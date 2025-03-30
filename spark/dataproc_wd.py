from pyspark.sql import SparkSession
from pyspark.sql.functions import col, hour, date_format, count, avg, max as spark_max, countDistinct
from datetime import datetime, timedelta

dataset_id = "zoomcamp-uniqueid-1337.zoomcamp_dataset.taxi"
ouput_table_id = "zoomcamp-uniqueid-1337.zoomcamp_dataset.region_"
gcs_bucket = "zoomcamp_4_2025_qwik/temp"

# Initialize Spark session
spark = SparkSession.builder \
    .appName("RegionAggregation") \
    .config("spark.jars.packages", "com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.28.0") \
    .getOrCreate()

# Read data from BigQuery
df = spark.read.format("bigquery") \
    .option("table", dataset_id) \
    .load()

# Cast the necessary columns to their correct types if needed
df = df.withColumn("hour_bin", (hour(col("insertion_time")) / 4).cast("integer") * 4)

# Find the maximum date in the data
max_date = df.agg(spark_max("insertion_time")).collect()[0][0]

# Determine the latest three weekdays based on the max_date
days_back = 0
weekdays = []
while len(weekdays) < 3:
    potential_day = max_date - timedelta(days=days_back)
    if potential_day.weekday() < 5:  # Monday to Friday are 0 to 4
        weekdays.append(potential_day.strftime('%Y-%m-%d'))
    days_back += 1
    
# Determine the latest 2 weekend based on the max_date
days_back = 0
weekends = []
while len(weekends) < 2:
    potential_day = max_date - timedelta(days=days_back)
    if potential_day.weekday() >= 5:  # Saturday and Sunday are 5 and 6
        weekends.append(potential_day.strftime('%Y-%m-%d'))
    days_back += 1

# Filter for the latest three weekdays only
df_filtered = df.filter(date_format(col("insertion_time"), "yyyy-MM-dd").isin(weekdays))
# Filter for the latest two weekends only
df_filtered_WE = df.filter(date_format(col("insertion_time"), "yyyy-MM-dd").isin(weekends))

# Aggregate counts by nearest_region and hour_bin
agg_df = df_filtered.groupBy("nearest_region", "hour_bin").agg(count("*").alias("count"))
agg_df_WE = df_filtered_WE.groupBy("nearest_region", "hour_bin").agg(count("*").alias("count"))

# Count distinct timestamps per nearest_region and hour_bin
timestamp_count_df = df_filtered.groupBy("nearest_region", "hour_bin").agg(countDistinct("insertion_time").alias("timestamp_count"))
timestamp_count_df_WE = df_filtered_WE.groupBy("nearest_region", "hour_bin").agg(countDistinct("insertion_time").alias("timestamp_count"))

joined_df = agg_df.join(timestamp_count_df, ["nearest_region", "hour_bin"], "inner")
joined_df_WE = agg_df_WE.join(timestamp_count_df_WE, ["nearest_region", "hour_bin"], "inner")

# Calculate the adjusted average count per weekday for each region and time bin
avg_df = joined_df.withColumn("adjusted_average_count", col("count") / col("timestamp_count")) \
                  .select("nearest_region", "hour_bin", "adjusted_average_count") \
                  .orderBy("nearest_region", "hour_bin")

# Write the result to BigQuery
try:
    avg_df.write.format("bigquery") \
        .option("table", ouput_table_id + "weekday") \
        .option("temporaryGcsBucket", gcs_bucket) \
        .mode("overwrite") \
        .save()
except Exception as e:
    print(f"Error writing avg_df to BigQuery (weekday): {e}")
    
# Calculate the adjusted average count per weekend for each region and time bin
avg_df_WE = joined_df_WE.withColumn("adjusted_average_count", col("count") / col("timestamp_count")) \
                  .select("nearest_region", "hour_bin", "adjusted_average_count") \
                  .orderBy("nearest_region", "hour_bin")

try:
    avg_df_WE.write.format("bigquery") \
        .option("table", ouput_table_id + "weekend") \
        .option("temporaryGcsBucket", gcs_bucket) \
        .mode("overwrite") \
        .save()
except Exception as e:
    print(f"Error writing avg_df_WE to BigQuery (weekend): {e}")
