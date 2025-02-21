data "aws_route53_zone" "zone" { # Data resource to get a resource that exists in aws
  name = "${var.dns_zone_name}."
}

# Create a record in Route53 to point to the load balancer
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id # Which zone we are creating the record in
  # Lookup looks at the subdomain and gets the workspace
  name = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}" # Name of the record, full dns name, ex:api.staging.davidmartinezhid.com
  type = "CNAME"                                                                            # Type of domain name record. Canonical name, to map one dns name to another in the load balancer
  ttl  = "300"                                                                              # Time to live, how often the changes get reflected on the cache of the record. It affects new environments, propagates changes

  # So we foward request to the load balancer
  records = [aws_lb.api.dns_name] # We are mapping it to the load balancer, so thats the domain name we are pointing to
}
