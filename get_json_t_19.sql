create or replace function get_json_t
/* vb
select t.id zzp_id
      ,t.document
  from get_json_t(p_tab              => b2b_zzp
                 ,p_exclude_cols     => columns(aangemaakt_door, gewijzigd_door, datum_aangemaakt, datum_gewijzigd)
                 ,p_date_columns     => columns(geboorte_datum)
                 ,p_boolean_columns  => columns(btw_vrij, btw_verlegd)
                 ,p_hide_null_values => 1) t
*/
(
  p_tab              in dbms_tf.table_t
 ,p_exclude_cols     in dbms_tf.columns_t default null
 ,p_date_columns     dbms_tf.columns_t default null
 ,p_boolean_columns  dbms_tf.columns_t default null
 ,p_hide_null_values in integer default 1
) return clob sql_macro is
  l_column_name varchar2(128);
  type key_value_rectype is record(
     k varchar2(128)
    ,v varchar2(128));
  type key_value_tabtype is table of key_value_rectype index by pls_integer;
  l_key_value_list   key_value_tabtype;
  l_stmt             clob;
  j                  pls_integer := 1;
  l_hide_null_values boolean := (p_hide_null_values = 1);
begin
  for i in 1 .. p_tab.column.count
  loop
    if (p_exclude_cols is null or not p_tab.column(i).description.name member of p_exclude_cols)
    then
      -- trim column name
      l_column_name := trim(both '"' from p_tab.column(i).description.name);
    
      -- camelcase key
      l_key_value_list(j).k := substr(lower(l_column_name), 1, 1) || substr(replace(initcap(l_column_name), '_'), 2);    
      -- value
      l_key_value_list(j).v := case
        when (
          p_date_columns is not null
          and p_tab.column(i).description.name member of p_date_columns
        ) then
          'to_char(' || p_tab.column(i).description.name || ', ''yyyy-mm-dd'')'
        when (
          p_boolean_columns is not null
          and p_tab.column(i).description.name member of p_boolean_columns
        ) then
          'decode(lower(' || p_tab.column(i).description.name || '),''j'',''true'', ''ja'',''true'', ''y'', ''true'',''false'') format json'
        else p_tab.column(i).description.name
      end || ',';    
      j := j + 1;
    end if;
  end loop;

  if (l_key_value_list.exists(1))
  then
    l_key_value_list(l_key_value_list.last()).v := rtrim(l_key_value_list(l_key_value_list.last()).v, ',');
  end if;

  l_stmt := 'select t.*, json_object(';
  for i in 1 .. l_key_value_list.count
  loop
    l_stmt := l_stmt || '''' || l_key_value_list(i).k || ''':' || l_key_value_list(i).v;
  end loop;

  if (l_hide_null_values)
  then
    l_stmt := l_stmt || ' absent on null returning clob) document from p_tab t';
  else
    l_stmt := l_stmt || ' returning clob) document from p_tab t';
  end if;

  dbms_tf.trace(l_stmt);
  return l_stmt;
end get_json_t;
