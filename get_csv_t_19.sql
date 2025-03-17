create or replace function get_csv_t (
   p_tab          in dbms_tf.table_t,
   p_date_columns in dbms_tf.columns_t default null,
   p_settings     in dbms_tf.columns_t default null
) return clob sql_macro as
/* example:
  with data as (
    select t.empno,
            t.ename,
            t.hiredate,
            t.sal
      from emp t
  )
  select *
    from get_csv_t(
    p_tab          => data,
    p_date_columns => columns(hiredate),
    p_settings     => columns(
        "delimiter|;",
        "date-format|dd-mm-yyyy",
        "enclosed-by|true",
        "header|true"
    )
  );
*/
  --
   c_delimiter        constant varchar2(1) := ',';
   c_date_format      constant varchar2(10) := 'dd-mm-yyyy';
   c_enclosed_by      constant varchar2(1) := '"';
  --
   l_delimiter        varchar2(1) := c_delimiter;
   l_delimiter_record varchar2(20);
   l_date_format      varchar2(100) := c_date_format;
   l_datetime_format  varchar2(100);
   l_timestamp_format varchar2(100);
   l_enclosed_by      boolean := true;
   l_include_header   boolean := true;
   l_record           clob;
   l_column_name      varchar2(200);
   l_column           varchar2(4000);
   l_header           clob;
   l_sql_template     clob;
   l_sql              clob;
   l_setting          varchar2(1000);
   type t_settings is
      table of varchar2(100) index by varchar2(100);
   l_settings         t_settings;
begin
   -- get the settings
   for i in 1..p_settings.count() loop
      l_setting := trim(both '"' from p_settings(i));
      l_settings(regexp_substr(
         l_setting,
         '^(.*)\|',
         1,
         1,
         null,
         1
      )) := regexp_substr(
         l_setting,
         '\|(.*)',
         1,
         1,
         null,
         1
      );
   end loop;

  -- set the delimiter
   if ( l_settings.exists('delimiter') ) then
      l_delimiter := nvl(
         l_settings('delimiter'),
         c_delimiter
      );
   end if;
   l_delimiter_record := '||'''
                         || l_delimiter
                         || '''||';
  -- set date / time formats
   if ( l_settings.exists('date-format') ) then
      l_date_format := nvl(
         l_settings('date-format'),
         c_date_format
      );
   end if;
   l_datetime_format := l_date_format || ' hh24:mi:ss';
   l_timestamp_format := l_datetime_format || '.ff';

  -- set enclosed by
   if ( l_settings.exists('enclosed-by') ) then
      l_enclosed_by := ( lower(l_settings('enclosed-by')) = 'true' );
   end if;

  -- set include header
   if ( l_settings.exists('header') ) then
      l_include_header := ( lower(l_settings('header')) = 'true' );
   end if;

   for i in 1..p_tab.column.count() loop
      l_column_name := trim(both '"' from p_tab.column(i).description.name);

      case
    -- strings
         when ( p_tab.column(i).description.type in ( dbms_tf.type_varchar2,
                                                      dbms_tf.type_char,
                                                      dbms_tf.type_clob ) ) then
            if ( l_enclosed_by ) then
               l_column := ''''
                           || c_enclosed_by
                           || '''||'
                           || l_column_name
                           || '||'''
                           || c_enclosed_by
                           || '''';
            else
               l_column := l_column_name;
            end if;
      
    -- numbers  
         when ( p_tab.column(i).description.type in ( dbms_tf.type_number,
                                                      dbms_tf.type_binary_float,
                                                      dbms_tf.type_binary_double ) ) then
            l_column := 'to_char('
                        || l_column_name
                        || ')';
      
    -- dates
         when ( p_tab.column(i).description.type = dbms_tf.type_date ) then
            if (
               p_date_columns is not null
               and p_tab.column(i).description.name member of p_date_columns
            ) then
               l_column := 'to_char('
                           || l_column_name
                           || ','''
                           || l_date_format
                           || ''')';
            else
               l_column := 'to_char('
                           || l_column_name
                           || ','''
                           || l_datetime_format
                           || ''')';
            end if;
      
    -- timestamps
         when ( p_tab.column(i).description.type = dbms_tf.type_timestamp ) then
            l_column := 'to_char('
                        || l_column_name
                        || ','''
                        || l_timestamp_format
                        || ''')';
         else
            l_column := l_column_name;
      end case;
  
    -- header
      if ( l_include_header ) then
         if ( l_enclosed_by ) then
            l_header := l_header
                        || c_enclosed_by
                        || l_column_name
                        || c_enclosed_by;
         else
            l_header := l_header || l_column_name;
         end if;
      end if;
  
    -- record
      l_record := l_record || l_column;
  
    -- add delimiter
      if ( i < p_tab.column.count() ) then
         if ( l_include_header ) then
            l_header := l_header || l_delimiter;
         end if;
         l_record := l_record || l_delimiter_record;
      end if;
   end loop;

   if ( l_include_header ) then
      l_sql_template := q'[
              with d as (
               select '%HEADER%' csv_row, 1 ro from dual
              union all
              select %RECORD% csv_row, 2 ro from p_tab
              )
              select csv_row from d order by ro
         ]';
   else
      l_sql_template := q'[              
              select %RECORD% csv_row from p_tab
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