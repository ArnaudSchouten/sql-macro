create or replace function get_json (
  p_columns          dbms_tf.columns_t
 ,p_hide_null_values boolean default true
 ,p_date_columns     in dbms_tf.columns_t default null
 ,p_boolean_columns  in dbms_tf.columns_t default null
) return clob sql_macro ( scalar ) is

  l_column_name    varchar2(200);
  type key_value_rectype is record (
      k varchar2(200)
    ,v varchar2(200)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list key_value_tabtype;
  l_stmt           clob;
begin
  for i,col in pairs of p_columns loop
    l_column_name         := replace(col,'"','''');
    l_key_value_list(i).k := substr(lower(l_column_name),1,2) || substr(replace(initcap(l_column_name),'_'),3);

    l_key_value_list(i).v := case
      when (
        p_date_columns is not null
        and col member of p_date_columns
      ) then
        'to_char(' || col || ', ''yyyy-mm-dd'')'
      when (
        p_boolean_columns is not null
        and col member of p_boolean_columns
      ) then
        'decode(lower(' || col || '),''j'',''true'', ''ja'',''true'', ''y'', ''true'',''false'') format json'
      else col
    end || ',';

  end loop;

  if ( l_key_value_list.count() > 0 ) then
    l_key_value_list(l_key_value_list.last()).v := rtrim(l_key_value_list(l_key_value_list.last()).v,',');
  end if;

  l_stmt := 'json_object(';
  for val in values of l_key_value_list loop
    l_stmt := l_stmt || val.k || ':' || val.v;
  end loop;

  if ( p_hide_null_values ) then
    l_stmt := l_stmt || ' absent on null returning json)';
  else
    l_stmt := l_stmt || 'returning json)';
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json;