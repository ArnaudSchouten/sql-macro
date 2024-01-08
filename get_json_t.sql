create or replace function get_json_t (
  p_tab              in dbms_tf.table_t
 ,p_exclude_cols     in dbms_tf.columns_t
 ,p_hide_null_values boolean default true
) return clob
  sql_macro ( table )
is

  l_column_name    varchar2(1000);
  type key_value_rectype is record (
      k varchar2(1000)
    ,v varchar2(1000)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list key_value_tabtype;
  l_stmt           varchar2(32767);
  j                pls_integer := 1;
begin
  for i in 1..p_tab.column.count loop
    if ( not p_tab.column(i).description.name member of p_exclude_cols or p_exclude_cols is null ) then
      l_column_name         := trim(both '"' from p_tab.column(i).description.name);

      dbms_tf.trace(l_column_name);
      l_key_value_list(j).k := substr(lower(l_column_name),1,1) || substr(replace(initcap(l_column_name),'_'),2);

      if ( i < p_tab.column.count ) then
        l_key_value_list(j).v := p_tab.column(i).description.name || ',';
      else
        l_key_value_list(j).v := p_tab.column(i).description.name;
      end if;

      j                     := j + 1;
    end if;
  end loop;

  l_stmt := 'select json_object(';
  for i in 1..l_key_value_list.count loop
    l_stmt := l_stmt || '''' || l_key_value_list(i).k || ''':' || l_key_value_list(i).v;
  end loop;

  if ( p_hide_null_values ) then
    l_stmt := l_stmt || ' absent on null) from p_tab';
  else
    l_stmt := l_stmt || ') from p_tab';
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json_t;