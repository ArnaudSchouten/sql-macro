create or replace function get_csv_t (
   p_tab             in dbms_tf.table_t,
   p_include_header  in boolean default true,
   p_demiliter       in varchar2 default ',',
   p_exclude_columns in dbms_tf.columns_t default null,
   p_date_columns    in dbms_tf.columns_t default null
) return clob
   sql_macro ( table )
as
   l_record       clob;
   l_column_name  varchar2(200);
   l_delimiter    varchar2(1) := nvl(
      p_demiliter,
      ','
   );
   l_enclosed_by  varchar2(1) := '"';
   l_header       clob;
   l_sql_template clob;
   l_sql          clob;
begin
   for col in values of p_tab.column loop
      if ( p_exclude_columns is null
      or not col.description.name member of p_exclude_columns ) then
         l_column_name := replace(
            col.description.name,
            '"'
         );
         l_header := l_header
                     || l_enclosed_by
                     || l_column_name
                     || l_enclosed_by
                     || l_delimiter;
         case
            when ( col.description.type in ( dbms_tf.type_varchar2,
                                             dbms_tf.type_char,
                                             dbms_tf.type_clob ) ) then
               l_record := l_record
                           || ''''
                           || l_enclosed_by
                           || '''||'
                           || l_column_name
                           || '||'''
                           || l_enclosed_by
                           || ''''
                           || '||'''
                           || l_delimiter
                           || '''||';
            when ( col.description.type in ( dbms_tf.type_number,
                                             dbms_tf.type_binary_float,
                                             dbms_tf.type_binary_double ) ) then
               l_record := l_record
                           || 'to_char('
                           || l_column_name
                           || ')||'''
                           || l_delimiter
                           || '''||';
            when ( col.description.type = dbms_tf.type_date ) then
               if (
                  p_date_columns is not null
                  and col.description.name member of p_date_columns
               ) then
                  l_record := l_record
                              || 'to_char('
                              || l_column_name
                              || ',''YYYY-MM-DD'')||'''
                              || l_delimiter
                              || '''||';
               else
                  l_record := l_record
                              || 'to_char('
                              || l_column_name
                              || ',''YYYY-MM-DD HH24:MI:SS'')||'''
                              || l_delimiter
                              || '''||';
               end if;
            when ( col.description.type = dbms_tf.type_timestamp ) then
               l_record := l_record
                           || 'to_char('
                           || l_column_name
                           || ',''YYYY-MM-DD HH24:MI:SS.FF'')||'''
                           || l_delimiter
                           || '''||';
            else
               l_record := l_record
                           || l_column_name
                           || '||'''
                           || l_delimiter
                           || '''||';
         end case;
      end if;
   end loop;

   l_record := rtrim(
      l_record,
      '||'''
      || l_delimiter
      || ''
   );
   l_header := rtrim(
      l_header,
      l_delimiter
   );
   if ( p_include_header ) then
      l_sql_template := q'[
                with d as (
                select '%HEADER%' as csv_row, 1 as row_order from dual 
                union all 
                select %RECORD% as csv_row , 2 as row_order from p_tab
                ) 
                select csv_row from d order by row_order
           ]';
   else
      l_sql_template := q'[
                 select %RECORD% as csv_row from p_tab
              ]';
   end if;

   l_sql := replace(
      replace(
         l_sql_template,
         '%HEADER%',
         l_header
      ),
      '%RECORD%',
      l_record
   );

   dbms_output.put_line(l_sql);
   return l_sql;
end get_csv_t;