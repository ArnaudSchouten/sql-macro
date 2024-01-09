create or replace type string_type as object (
  v varchar2(4000)
);
/

create or replace function get_json_t (
  p_tab              in dbms_tf.table_t
 ,p_exclude_cols     in dbms_tf.columns_t default null
 ,p_hide_null_values in boolean default true
 ,p_json_column      in string_type default null
) return clob
  sql_macro ( table )
is

  l_column_name      varchar2(32767);
  l_json_column_name varchar2(32767);
  type key_value_rectype is record (
      k varchar2(1000)
    ,v varchar2(1000)
  );
  type key_value_tabtype is
    table of key_value_rectype index by pls_integer;
  l_key_value_list   key_value_tabtype;
  l_stmt             varchar2(32767);
  j                  pls_integer := 1;
begin
  for i in 1..p_tab.column.count loop
    if ( p_exclude_cols is null or not p_tab.column(i).description.name member of p_exclude_cols ) then
      l_column_name         := trim(both '"' from p_tab.column(i).description.name);

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

  if ( p_json_column is null ) then
    if ( p_hide_null_values ) then
      l_stmt := l_stmt || ' absent on null) document from p_tab t';
    else
      l_stmt := l_stmt || ') document from p_tab t';
    end if;
  else
    if ( p_hide_null_values ) then
      l_stmt := l_stmt || ' absent on null) ' || p_json_column.v || ' from p_tab t';
    else
      l_stmt := l_stmt || ') ' || p_json_column.v || ' from p_tab t';
    end if;
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json_t;