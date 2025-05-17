import fsspec
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr
import tempfile

def get_spark_session():
    """
    Crea una sesión de Spark.
    """
    spark = SparkSession.builder \
        .appName("Local PySpark Job") \
        .master("local[*]") \
        .config("spark.jars.packages", "org.apache.hadoop:hadoop-aws:3.3.4") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "true") \
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", "com.amazonaws.auth.DefaultAWSCredentialsProviderChain") \
        .config("spark.hadoop.fs.s3a.endpoint", "s3.amazonaws.com") \
        .getOrCreate()
    return spark

def read_csv_from_s3(spark, s3_path):
    """
    Lee un archivo CSV desde S3 y lo devuelve como un DataFrame de Spark.
    """
    # Leer el archivo CSV desde S3
    # Abrir archivo desde S3 con fsspec
    with fsspec.open(s3_path, mode="rb") as f:
        # Guardarlo temporalmente para que Spark lo lea
        with tempfile.NamedTemporaryFile(delete=False, suffix=".csv") as tmp:
            tmp.write(f.read())
            temp_path = tmp.name
    df = spark.read.option("header", True).csv(temp_path)
    return df

def clean_data(df):
    """
    Limpia los datos del DataFrame.
    """
    # Eliminar filas con valores nulos
    df = df.dropna()
    # Eliminar duplicados
    df = df.dropDuplicates()
   
    return df

def main():
    """
    Función principal para ejecutar el trabajo de transformación.
    """
    # Crear SparkSession
    spark = get_spark_session()
    # Ruta en S3
    s3_path = ("s3://btg-s3-data-raw/clientes/year=2024/month=05/clientes.csv",
               "s3://btg-s3-data-raw/proveedores/year=2024/month=05/proveedores.csv",
               "s3://btg-s3-data-raw/transacciones/year=2024/month=05/transacciones.csv",
    )
    # Leer el archivo CSV desde S3
    s3_clientes = s3_path[0]
    s3_proveedores = s3_path[1]
    s3_transacciones = s3_path[2]
    df_clientes = read_csv_from_s3(spark, s3_clientes)
    df_proveedores = read_csv_from_s3(spark, s3_proveedores)
    df_transacciones = read_csv_from_s3(spark, s3_transacciones)
    # Mostrar el DataFrame
    df_clientes.show()

    # Limpiar los datos
    df_clientes = clean_data(df_clientes)
    df_proveedores = clean_data(df_proveedores)
    df_transacciones = clean_data(df_transacciones)

    # convertir a minuscula los nombres de los clientes
    df_clientes = (
        df_clientes.selectExpr(
            "cliente_id",
            "tipo_identificacion",
            "lower(nombre) as nombre_cliente",
            "ciudad"
            )
    )
    # convertir los campos cantidad_comprada y precio a entero
    df_transacciones = (
        df_transacciones.select(
            col("transaccion_id"),
            col("tipo_transaccion"),
            col("id_cliente_proveedor"),
            col("cantidad_comprada").cast("int"),
            col("precio").cast("int"),
            col("tipo_energia")
        )
    )

    #guardar data en la zona curada en formato parquet
    df_clientes.write.mode("overwrite").parquet("s3a://btg-s3-data-curated/clientes/year=2024/month=05/")
    df_proveedores.write.mode("overwrite").parquet("s3a://btg-s3-data-curated/proveedores/year=2024/month=05/")
    df_transacciones.write.mode("overwrite").parquet("s3a://btg-s3-data-curated/transacciones/year=2024/month=05/")

if __name__ == "__main__":
    main()