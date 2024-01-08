create or replace function valid_vw (
    p_tab in dbms_tf.table_t
   ,p_cols in dbms_tf.columns_t
   ,p_date in date default trunc(sysdate)
) return varchar2 sql_macro as
  l_stmt long;
begin
  l_stmt := 'select * 
               from p_tab t 
              where t.' ||p_cols(1)||' <= p_date 
                and (t.'||p_cols(2)||' is null or t.'||p_cols(2)||' >= p_date)';
  
  dbms_tf.trace(l_stmt);
  
  return l_stmt;

end valid_vw;