# 🧠 BTG Energy DataLake Project

Este proyecto representa una solución analítica basada en AWS para una compañía comercializadora de energía. La compañía administra información sobre **proveedores, clientes y transacciones**, que se exportan desde sus sistemas como archivos CSV.

El objetivo es construir una arquitectura de procesamiento de datos moderna y escalable sobre AWS utilizando servicios como **S3, AWS Glue, Athena y Terraform**.

---

## 📌 Enunciado

Una compañía comercializadora de energía compra la electricidad a los generadores y luego la vende a usuarios finales (residenciales, comerciales o industriales). La compañía puede exportar archivos CSV con información de:

- Proveedores  
- Clientes  
- Transacciones

---

## ⚙️ Requisitos Técnicos

1. ✅ **Estrategia de Datalake** en Amazon S3, estructurada en capas y con almacenamiento particionado por fecha.
2. ✅ **Transformaciones** básicas utilizando AWS Glue. La salida se almacena como archivos **Parquet** en la zona procesada.
3. ✅ **Crawler automático** de AWS Glue para detectar y catalogar los datos en cada nueva carga.
4. ✅ **Consultas SQL en Athena** desde Python, para extraer insights de los datos transformados.

---

## 🗂️ Estructura del Proyecto
```text
📁 BTG_PROJECT/
   └── data/ # Carpeta local donde residen archivos CSV de ejemplo
   └── glue/
   | └── btg_transformation.py # Script PySpark con las transformaciones en Glue
   └── iac/
   | └──  main.tf # Infraestructura como código con Terraform
   └── .gitignore
   └── README.md
```
---

## 🏗️ Arquitectura

```
📁 Raw Layer (S3 bucket)
   └── proveedores/
   └── clientes/
   └── transacciones/

🔄 AWS Glue Crawler
   └── Detecta y cataloga nuevos archivos

🧪 AWS Glue Job
   └── Realiza transformaciones básicas en PySpark

📁 Processed Layer (S3 bucket)
   └── parquet/proveedores/
   └── parquet/clientes/
   └── parquet/transacciones/

🔍 Amazon Athena
   └── SQL sobre las tablas catalogadas
```

---

## 🔄 Transformaciones Realizadas

1. Las transformaciones básicas implementadas en btg_transformation.py incluyen:
2. Limpieza de datos nulos o mal formateados.
3. Conversión de tipos de datos adecuados.
4. Escritura de los resultados como archivos Parquet particionados por year y month.

---

## 🚀 Despliegue

### 1. Inicializa la infraestructura

```bash
cd iac
terraform init
terraform apply
```

Esto creará:

- Buckets en S3
- Glue Crawlers
- Glue Jobs
- Tablas en Glue Data Catalog

### 2. Sube tus archivos CSV

Coloca los archivos CSV de `clientes`, `proveedores`, `transacciones` en la ruta `s3://<bucket>/raw/<tabla>/year=YYYY/month=MM/`.

### 3. Ejecuta los procesos

Puedes ejecutar manualmente el **Glue Job** o crear un **Trigger** periódico desde consola.

También puedes ejecutar consultas desde Athena o desde Python con `boto3` o `PyAthena`.

---

## 🧠 Consultas Athena desde Python

Se pueden realizar consultas básicas como: detalle de transacciones realizadas por cliente.

```sql
select 
    c.*,
    t.transaccion_id,
    tipo_transaccion,
    cantidad_comprada,
    t.precio,
    t.tipo_energia,
    t.year,
    t.month 
from transacciones_transacciones t
join clientes_clientes c on t.id_cliente_proveedor = c.cliente_id
;
```

---

## 🛠️ Tecnologías Utilizadas

- **AWS S3**: Almacenamiento de datos en capas
- **AWS Glue**: Transformaciones, catalogación, crawlers
- **AWS Athena**: Motor SQL serverless para análisis
- **Terraform**: Infraestructura como código
- **Python + PySpark**: Procesamiento de datos

---

## 📎 Notas Finales

- Todo el procesamiento está particionado por `year` y `month` de carga.
- El Glue Crawler se actualiza automáticamente al detectar nuevos archivos.
- Las transformaciones son idempotentes: no sobrescriben datos antiguos.

---

## 🧑‍💻 Autor

Este proyecto fue desarrollado como ejercicio técnico de arquitectura de datos sobre AWS.