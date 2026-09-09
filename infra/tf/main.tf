terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "env" {
  description = "Ambiente di destinazione"
  type        = string
  default     = "test"
  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "env deve essere dev, test o prod."
  }
}

variable "owner" {
  description = "Squadra responsabile della risorsa"
  type        = string
  default     = "squadra-0"
  validation {
    condition     = length(var.owner) >= 3
    error_message = "owner deve avere almeno 3 caratteri."
  }
}

variable "aws_endpoint" {
  description = "Endpoint alternativo; vuoto usa AWS, localhost:5000 usa Moto."
  type        = string
  default     = ""
}

variable "supplier_principal_arn" {
  description = "ARN IAM verificato del fornitore; vuoto lascia disattivato l'accesso."
  type        = string
  default     = ""
}

provider "aws" {
  region = "eu-south-1"

  access_key                  = var.aws_endpoint == "" ? null : "test"
  secret_key                  = var.aws_endpoint == "" ? null : "test"
  skip_credentials_validation = var.aws_endpoint != ""
  skip_metadata_api_check     = var.aws_endpoint != ""
  skip_requesting_account_id  = var.aws_endpoint != ""
  s3_use_path_style           = var.aws_endpoint != ""

  endpoints {
    s3       = var.aws_endpoint
    dynamodb = var.aws_endpoint
    kms      = var.aws_endpoint
    sts      = var.aws_endpoint
  }
}

locals {
  suffisso = "${var.env}-${var.owner}"
  tag_comuni = {
    Owner    = var.owner
    Env      = var.env
    Progetto = "portale-its"
  }
}

data "aws_caller_identity" "attuale" {}

#checkov:skip=CKV_AWS_18:Il bucket dei log non registra se stesso per evitare ricorsione.
resource "aws_s3_bucket" "log" {
  bucket = "portale-its-log-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "log" {
  bucket = aws_s3_bucket.log.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ConsentiScritturaLogS3"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.log.arn}/*"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.attuale.account_id
        }
      }
    }]
  })
}

resource "aws_s3_bucket" "sito" {
  bucket = "portale-its-sito-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_versioning" "sito" {
  bucket = aws_s3_bucket.sito.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "sito" {
  bucket        = aws_s3_bucket.sito.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "sito/${var.env}/"
  depends_on    = [aws_s3_bucket_policy.log]
}

resource "aws_s3_bucket" "scambio" {
  bucket = "portale-its-scambio-${local.suffisso}"
  tags   = local.tag_comuni
}

resource "aws_s3_bucket_versioning" "scambio" {
  bucket = aws_s3_bucket.scambio.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scambio" {
  bucket = aws_s3_bucket.scambio.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scambio" {
  bucket                  = aws_s3_bucket.scambio.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "scambio" {
  bucket        = aws_s3_bucket.scambio.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "scambio/${var.env}/"
  depends_on    = [aws_s3_bucket_policy.log]
}

resource "aws_s3_bucket_policy" "fornitore" {
  count  = var.supplier_principal_arn == "" ? 0 : 1
  bucket = aws_s3_bucket.scambio.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "ConsentiSoloUploadFornitore"
      Effect    = "Allow"
      Principal = { AWS = var.supplier_principal_arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.scambio.arn}/incoming/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-server-side-encryption" = "AES256"
        }
      }
    }]
  })
}

resource "aws_kms_key" "iscrizioni" {
  description         = "Chiave di cifratura della tabella iscrizioni del portale ITS"
  enable_key_rotation = true
  tags                = local.tag_comuni
}

resource "aws_dynamodb_table" "iscrizioni" {
  name         = "portale-its-iscrizioni-${local.suffisso}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "iscrizioneId"

  attribute {
    name = "iscrizioneId"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.iscrizioni.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.tag_comuni
}

output "bucket_sito" {
  description = "Bucket privato usato nel collaudo del portale"
  value       = aws_s3_bucket.sito.id
}

output "bucket_log" {
  description = "Bucket dei log di accesso"
  value       = aws_s3_bucket.log.id
}

output "bucket_scambio" {
  description = "Bucket in sola scrittura per il fornitore"
  value       = aws_s3_bucket.scambio.id
}

output "tabella_iscrizioni" {
  description = "Tabella delle iscrizioni"
  value       = aws_dynamodb_table.iscrizioni.name
}
