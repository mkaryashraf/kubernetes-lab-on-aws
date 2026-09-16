resource "aws_iam_policy" "aws_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "policy for aws controller to integrate with aws api for LoadBalancer and other resources"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:DescribeRouteTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeListenerAttributes"
        ],
        "Resource" : "*"
      },
      # Upstream's Cognito / ACM / WAF / Shield statement is deliberately absent.
      # No Ingress here carries an auth-type, wafv2-acl-arn, or shield-advanced
      # annotation, and the ALB is HTTP:80 only, so the controller never makes
      # these calls. Re-add the statement if you add TLS, WAF, or Cognito auth.
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      # Upstream also lists AuthorizeSecurityGroupIngress and
      # RevokeSecurityGroupIngress here. Both are already granted unconditioned
      # above, so the tag-conditioned copy grants nothing extra. Dropped to keep
      # one grant per action. DeleteSecurityGroup is only granted here, so the
      # tag condition is the real boundary for it.
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        "Resource" : "*"
      },
      # The net/ (network load balancer) ARN patterns from upstream are dropped
      # throughout: this lab creates no type=LoadBalancer Service and its only
      # Ingress is an ALB, so no NLB ever exists to tag. Add them back if you
      # create one.
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      # Dropped from this statement, because the controller only calls them when
      # the corresponding setting drifts from what CreateLoadBalancer already set,
      # and nothing here changes it:
      #   SetIpAddressType  - needs an alb.ingress.kubernetes.io/ip-address-type
      #                       annotation. No Ingress has one, so the ALB stays on
      #                       the ipv4 it was created with.
      #   SetSubnets        - fires when the discovered subnet set changes. Subnets
      #                       come from the fixed kubernetes.io/role/elb tags in
      #                       aws_instances.tf and do not change.
      #   SetSecurityGroups - fires when the ALB's security-group set changes.
      #                       No security-groups annotation, so it does not.
      # Re-add whichever one you enable; symptom of a missing grant is the Ingress
      # stalling with an AccessDenied event, not a silent failure.
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListenerAttributes",
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "elasticloadbalancing:CreateAction" : [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "aws_api_role" {
  name               = "instance_role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}


resource "aws_iam_role_policy_attachment" "attach_aws_policy_to_instance_role" {
  role       = aws_iam_role.aws_api_role.name
  policy_arn = aws_iam_policy.aws_controller_policy.arn
}

# Serves the control-plane node only. The workers carry no instance profile
# (see aws_instances.tf), so the old "nodes-ec2-profile" name was misleading.
resource "aws_iam_instance_profile" "nodes_profile" {
  name = "control-plane-profile"
  role = aws_iam_role.aws_api_role.name
}

resource "aws_iam_policy" "aws_controller_manager_policy" {
  name        = "AWSManagerControllerIAMPolicy"
  description = "Node lifecycle only. No ELB permissions: the AWS Load Balancer Controller owns load balancers, and this lab creates no type=LoadBalancer Services."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  #
  # Trimmed from the legacy in-tree cloud-provider-aws "master" policy. Absent on
  # purpose:
  #   elasticloadbalancing:*  - the LBC owns load balancers here. A
  #                             type=LoadBalancer Service will fail without this.
  #   autoscaling:Describe*   - three standalone instances, no ASG.
  #   ec2:DescribeRouteTables - only used with --configure-cloud-routes=true,
  #                             and the Helm values set false.
  #   ec2:DescribeVolumes     - legacy in-tree EBS; the CSI driver owns volumes.
  #   ec2:DescribeSubnets / DescribeSecurityGroups / DescribeVpcs
  #                           - load balancer placement, which the LBC does.
  #   iam:*ServerCertificate* - TLS on CCM-managed load balancers.
  #
  # ec2:DescribeInstances is also in AWSLoadBalancerControllerIAMPolicy. Both
  # policies hang off the same role today, so the grant is redundant, but each
  # controller needs it on its own. Kept in both so the policies stay valid
  # independently when the shared role is split (REVIEW.md 7.2).
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeInstanceTopology"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_aws_policy_for_manager_to_instance_role" {
  role       = aws_iam_role.aws_api_role.name
  policy_arn = aws_iam_policy.aws_controller_manager_policy.arn
}


resource "aws_iam_role_policy_attachment" "attach_aws_policy_for_ebs_driver_to_instance_role" {
  role       = aws_iam_role.aws_api_role.name
  policy_arn = data.aws_iam_policy.ebs_csi.arn
}