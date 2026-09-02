create or replace function compare_tables
(
  t1                 dbms_tf.table_t
 ,t2                 dbms_tf.table_t
 ,comparison_columns dbms_tf.columns_t
) return clob sql_macro as
  stmt        clob;
  column_list clob;
begin

  for col in 1 .. comparison_columns.count
  loop
    column_list := column_list || comparison_columns(col) || ',';
  end loop;
  column_list := rtrim(column_list, ',');

  stmt := q'!
  select ##COLUMNS##,
         case 
           when sum ( t1 ) > sum ( t2 ) then 't1'
           else 't2'
         end as source_table
  from   (
    select t1.*, 1 t1, 0 t2 from t1
    union  all
    select t2.*, 0 t1, 1 t2 from t2
  )
  group  by ##COLUMNS##
  having sum ( t1 ) <> sum ( t2 ) !';

  stmt := replace(stmt, '##COLUMNS##', column_list);

  return stmt;
end compare_tables;
/
