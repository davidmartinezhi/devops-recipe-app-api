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

# Certificates are issued and suppoported by browsers, so we certificate that the domain name is in fact our domain name and is valid
# So we need to validate the domain name
# There are different methods to validate the domain name, we are going to use DNS validation
# With the load balancer we need to do it with acm from aws
resource "aws_acm_certificate" "cert" { # Ask for a new certificate for our domain name
  domain_name       = aws_route53_record.app.name
  validation_method = "DNS" # Choose the DNS validation method, it allows us to use DNS entry in terraform

  lifecycle { # Create before destroy to smooth process of destroying environment that has this certifications
    create_before_destroy = true
  }
}

# We need to create a record in Route53 to validate the domain name
resource "aws_route53_record" "cert_validation" {

  # Resources in terraform have a 1 to 1 match with the resource in aws
  # With for_each we can have multiple resources manage by one resource, we traverse what is created with the aws certificate above
  for_each = {
    # For each domain validation option in the certificate, we are going to create a record in Route53
    # We map the records for each dynamic option created in the certificate
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  # Allow overrite to overrite if it needs modifications
  allow_overwrite = true
  name            = each.value.name                    # Name is from the loop
  records         = [each.value.record]                # Record is from the loop
  ttl             = 60                                 # TTL is time to live, how long the record is valid and how ofen it will refresh
  type            = each.value.type                    # Type of record is from the loop
  zone_id         = data.aws_route53_zone.zone.zone_id # Zone id is from the data resource
}

resource "aws_acm_certificate_validation" "cert" {                                           # Run the validation
  certificate_arn         = aws_acm_certificate.cert.arn                                     # Specify the cxertificate arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn] # Get the fqdn generated from the record
}
