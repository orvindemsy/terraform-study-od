
# resource "aws_route53_zone" "main" {
#   name = "somename.com"
# }

# resource "aws_route53_zone" "dev" {
#   name = "dev.somename.com"

#   tags = {
#     Environment = "dev"
#   }
# }

# resource "aws_route53_record" "dev-ns" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "dev.somename.com"
#   type    = "NS"
#   ttl     = "30"
#   records = aws_route53_zone.dev.name_servers
# }

# resource "aws_route53_record" "random-CNAME" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "random.somename.com"
#   type    = "NS"
#   ttl     = "30"
#   records = ["random_records"]
# }

# resource "local_file" "text"{
#   content = join(", ", aws_route53_zone.dev.name_servers)
#   filename = "${path.module}/text"
# }

resource "aws_acm_certificate" "demo-cert" {
  domain_name       = "demo-cert-terraform.com"
  subject_alternative_names = ["www.demo1.com", "www.demo2.com"]
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

