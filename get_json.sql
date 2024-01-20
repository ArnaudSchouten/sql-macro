create or replace function get_json (
  p_cols dbms_tf.columns_t
, p_hide_null_values boolean default true
, p_date_columns dbms_tf.columns_t default null
) return clob sql_macro ( scalar ) is
  l_column_name    varchar2(1000);
  type key_value_rectype is record (
    k varchar2(1000)
  , v varchar2(1000)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list key_value_tabtype;
  l_stmt           varchar2(32767);
begin
  for i in 1..p_cols.count loop
    l_column_name := trim(both '"' from p_cols(i));
    l_key_value_list(i).k := substr(lower(l_column_name), 1, 1)
                             || substr(replace(initcap(l_column_name), '_'), 2);
    if ( p_date_columns is not null
    and p_cols(i) member of p_date_columns ) then
      l_key_value_list(i).v := 'to_char('
                               || p_cols(i)
                               || ', ''yyyy-mm-dd''),';
    else
      l_key_value_list(i).v := p_cols(i)
                               || ',';
    end if;

    if ( i = p_cols.count ) then
      l_key_value_list(i).v := rtrim(l_key_value_list(i).v, ',');
    end if;
  end loop;

  l_stmt := 'json_object(';
  for i in 1..l_key_value_list.count loop
    l_stmt := l_stmt
              || ''''
              || l_key_value_list(i).k
              || ''':'
              || l_key_value_list(i).v;
  end loop;

  if ( p_hide_null_values ) then
    l_stmt := l_stmt
              || ' absent on null)';
  else
    l_stmt := l_stmt
              || ')';
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json;