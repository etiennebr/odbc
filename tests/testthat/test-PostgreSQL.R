test_that("PostgreSQL", {
  skip_unless_has_test_db({
    DBItest::make_context(odbc(), list(dsn = "PostgreSQL"), tweaks = DBItest::tweaks(temporary_tables = FALSE, placeholder_pattern = "?"), name = "PostgreSQL")
  })

  context("custom tests")
  test_that("show method works as expected with real connection", {
    skip_on_os("windows")
    con <- dbConnect(odbc(), "PostgreSQL")

    expect_output(show(con), "@localhost")
    expect_output(show(con), "Database: [a-z]+")
    expect_output(show(con), "PostgreSQL Version: ")
  })

  test_that("64 bit integers work with alternate mappings", {
    con_default <- dbConnect(odbc(), "PostgreSQL")
    con_integer64 <- dbConnect(odbc(), "PostgreSQL", bigint = "integer64")
    con_integer <- dbConnect(odbc(), "PostgreSQL", bigint = "integer")
    con_numeric <- dbConnect(odbc(), "PostgreSQL", bigint = "numeric")
    con_character <- dbConnect(odbc(), "PostgreSQL", bigint = "character")

    dbWriteTable(con_default, "test", data.frame(a = 1:10L), field.types = c(a = "BIGINT"))
    on.exit(dbRemoveTable(con_default, "test"))

    expect_is(dbReadTable(con_default, "test")$a, "integer64")
    expect_is(dbReadTable(con_integer64, "test")$a, "integer64")

    expect_is(dbReadTable(con_integer, "test")$a, "integer")

    expect_is(dbReadTable(con_numeric, "test")$a, "numeric")

    expect_is(dbReadTable(con_character, "test")$a, "character")
  })

  # This test checks whether when writing to a table and using
  # result_describe_parameters to offer descriptions of the data
  # we are attempting to write, our logic remains robust to the
  # case when the data being written has columns ordered
  # differently than the table we are targetting.
  test_that("Writing data.frame with column ordering different than target table", {
    tblName <- "test_order_write"
    con <- dbConnect(odbc(), "PostgreSQL")
    values <- data.frame(
      datetime = as.POSIXct(c(14, 15), origin = "2016-01-01", tz = "UTC"),
      name = c("one", "two"),
      num = 1:2,
      stringsAsFactors = FALSE)
    sql <- sqlCreateTable(con, tblName, values)
    dbExecute(con, sql)
    on.exit(dbRemoveTable(con, tblName))
    dbWriteTable(con, tblName, values[c(2, 3, 1)],
      overwrite = FALSE, append = TRUE)
    received <- DBI::dbReadTable(con, tblName)
    received <- received[order(received$num), ]
    row.names(received) <- NULL
    expect_equal(values, received)
  })

  DBItest::test_getting_started(c(
      "package_name", # Not an error
      NULL))
  DBItest::test_driver()
  DBItest::test_connection(c(
      "cannot_forget_disconnect",
      "clear_result_return_statement",
      "cannot_clear_result_twice_statement",
      NULL
    )
  )
  DBItest::test_result(c(
      "fetch_n_bad",                     # TODO
      "fetch_n_good_after_bad",          # TODO
      "fetch_no_return_value",           # TODO
      "get_query_n_bad",                     # todo
      "get_query_good_after_bad_n",                     # todo
      "get_query_n_zero_rows",                     # todo
      "fetch_no_return_value",           # TODO
      "data_raw.*", # cast(1 bytea) is not valid `cannot cast type integer to bytea`
      "^data_time$", "^data_time_.*", # `time()` function is not valid syntax
      "^data_timestamp.*", # We explicitly want to set tzone to UTC
      "data_64_bit_numeric_warning", # TODO
      "data_64_bit_lossless", # TODO
      "send_query_syntax_error", # TODO
      "get_query_syntax_error", # TODO
      "send_query_params", # TODO
      "fetch_n_multi_row_inf", # TODO
      "get_query_n_multi_row_inf", # TODO
      "get_query_n_incomplete", # TODO
      "get_query_params", # TODO
      "send_statement_params", # TODO
      "execute_params", # TODO
      NULL))
  DBItest::test_sql(c(
      "quote_identifier_vectorized", # Can't implement until https://github.com/rstats-db/DBI/issues/71 is closed
      "quote_identifier_special", # TODO
      "roundtrip_timestamp", # We explicitly want to set tzone to UTC
      "roundtrip_raw", #TODO
      "list_tables",
      ".*_table_name",
      "write_table_error", # TODO
      "unquote_identifier_vectorized", # TODO
      "create_table_overwrite", # TODO
      "create_table_error", # TODO
      "create_temporary_table", # TODO
      "append_table_.*", # TODO
      "append_roundtrip_.*", # TODO
      "append_table_.*", # TODO
      "temporary_table_.*", # TODO
      "roundtrip_64_bit_roundtrip", # TODO
      "roundtrip_character", # TODO
      "roundtrip_blob", # TODO
      "roundtrip_field_types", # TODO
      "write_table_append_incompatible",
      "write_table_row_names_default", # TODO
      "remove_table_temporary_arg", # TODO
      "remove_table_missing_succeed", # TODO
      "remove_table_temporary", # TODO
      "list_objects_features", # TODO
      "list_fields_wrong_table", # TODO
      "list_fields_quoted", # TODO
      "list_fields_object", # TODO
      NULL))
  DBItest::test_meta(c(
      "bind_logical", # DBItest coerces this to character
      "bind_multi_row.*", # We do not current support multi row binding
      "bind_timestamp_lt", # We do not support POSIXlt objects
      "bind_raw", # This test seems to be not quite working as expected
      "bind_.*", # TODO
      "has_completed_statement",
      "get_statement_statement",
      "column_info_consistent", # TODO
      "row_count_statement", # TODO
      "rows_affected_statement", # TODO
      "get_info_result", # TODO
      NULL))
  #DBItest::test_transaction(c(
      #NULL))
  DBItest::test_compliance(c(
      "compliance", # We are defining additional subclasses for OdbcConnections
      "reexport", # TODO
      NULL))

  test_roundtrip()
})
