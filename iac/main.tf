terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Provides an S3 bucket for storing Terraform state files
resource "aws_s3_bucket" "bucket_btg_raw" {
  bucket = "btg-s3-data-raw"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "btg-s3-data-raw"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "bucket_btg_curated" {
  bucket = "btg-s3-data-curated"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "btg-s3-data-curated"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "bucket_btg_analytics" {
  bucket = "btg-s3-data-analytics"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "btg-s3-data-analytics"
    Environment = "dev"
  }
}

# carga archivos inicales zona raw - cruda
resource "aws_s3_object" "csv_file_clientes" {
  bucket = aws_s3_bucket.bucket_btg_raw.bucket
  key    = "clientes/year=2024/month=05/clientes.csv"                  # Ruta dentro del bucket
  source = "${path.module}/../data/clientes/clientes.csv"               # Ruta local al archivo
  #etag   = filemd5("${path.module}/clientes.csv")

  content_type = "text/csv"
  acl          = "private"
}

resource "aws_s3_object" "csv_file_proveedores" {
  bucket = aws_s3_bucket.bucket_btg_raw.bucket
  key    = "proveedores/year=2024/month=05/proveedores.csv"                  # Ruta dentro del bucket
  source = "${path.module}/../data/proveedores/proveedores.csv"               # Ruta local al archivo
  #etag   = filemd5("${path.module}/proveedores.csv")

  content_type = "text/csv"
  acl          = "private"
}

resource "aws_s3_object" "csv_file_transacciones" {
  bucket = aws_s3_bucket.bucket_btg_raw.bucket
  key    = "transacciones/year=2024/month=05/transacciones.csv"                  # Ruta dentro del bucket
  source = "${path.module}/../data/transacciones/transacciones.csv"               # Ruta local al archivo
  #etag   = filemd5("${path.module}/transacciones.csv")

  content_type = "text/csv"
  acl          = "private"
}

###########################
# 1. Base de datos de Glue
###########################

resource "aws_glue_catalog_database" "btg_db" {
  name = "btg_analytics"
}

#####################################
# 2. Rol IAM para Glue con permisos
#####################################

resource "aws_iam_role" "glue_role" {
  name = "btg-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

######################################
# 3. Crawler para CLIENTES
######################################

resource "aws_glue_crawler" "clientes_crawler" {
  name          = "btg-clientes-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.btg_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.bucket_btg_curated.bucket}/clientes/"
  }

  table_prefix = "clientes_"

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  schedule = "cron(0 * * * ? *)"

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

######################################
# 4. Crawler para PROVEEDORES
######################################

resource "aws_glue_crawler" "proveedores_crawler" {
  name          = "btg-proveedores-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.btg_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.bucket_btg_curated.bucket}/proveedores/"
  }

  table_prefix = "proveedores_"

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

schedule = "cron(0 * * * ? *)"

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

######################################
# 5. Crawler para TRANSACCIONES
######################################

resource "aws_glue_crawler" "transacciones_crawler" {
  name          = "btg-transacciones-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.btg_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.bucket_btg_curated.bucket}/transacciones/"
  }

  table_prefix = "transacciones_"

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  schedule = "cron(0 * * * ? *)"

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

