module "create_subnet" {
  source  = "kmayer10/create_subnet/aws"
  version = "1.0.0"
  # insert the 4 required variables here
  name = var.name
  vpc_id = "vpc-0ce7889ae8fafd3f6"
  subnet_type = "public"
  subnet_counter = "20"
}