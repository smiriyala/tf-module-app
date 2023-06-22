data "aws_ami" "ami" {
    most_recent = true
    name_regex = "devops-practice-with-ansible"
    owners = [ "self" ]
}

##Option-1
##This Variable data is being passed ot userdata.sh file which runs
## ansible script using userdata option of launch instnace options.

/* data "template_file" "userdata" {
    template = file("${path.module}/userdata.sh")
    vars = {
        component   = var.component
        env         = var.env
    }
} */

##Option-2
## Using base64 fucntion adn passing variable values within template. check main.tf of user_data block


data "aws_caller_identity" "account" {}

##STEp-4
data "aws_route53_zone" "domain"{
    name = var.dns_domain
}