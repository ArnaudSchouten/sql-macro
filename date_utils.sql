CREATE OR REPLACE package date_utils as
  function day (
    d in date
  ) return varchar2 sql_macro ( scalar );

  function month (
    d in date
  ) return varchar2 sql_macro ( scalar );

  function year (
    d in date
  ) return varchar2 sql_macro ( scalar );

  function get_date (
    d in int
   ,m in int
   ,y in int
  ) return varchar2 sql_macro ( scalar );

  function get_diff (
    part in varchar2
   ,d1   in date
   ,d2   in date
  ) return varchar2 sql_macro ( scalar );

  function get_diff2 (
    part in varchar2
   ,t1   in timestamp
   ,t2   in timestamp
  ) return varchar2 sql_macro ( scalar );

end date_utils;
/


CREATE OR REPLACE package body date_utils as

  function day (
    d in date
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[
       to_number(to_char(d, 'dd'))
       ]';
  end day;

  function month (
    d in date
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[
      to_number(to_char(d, 'mm'))
      ]';
  end month;

  function year (
    d in date
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[
      to_number(to_char(d, 'yyyy'))
      ]';
  end year;

  function get_date (
    d in int
   ,m in int
   ,y in int
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[
      to_date(to_char(y, 'fm0000')||to_char(m, 'fm00')||to_char(d, 'fm00'),'yyyymmdd')
      ]';
  end get_date;

  function get_diff (
    part in varchar2
   ,d1   in date
   ,d2   in date
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[
       case rtrim(lower(part), 's')
         when 'year' then floor(months_between(d2, d1) / 12)
         when 'month' then floor(months_between(d2, d1))
         when 'week' then floor((d2-d1)/7)
         when 'day' then floor(d2-d1)
         when 'hour' then floor((d2-d1)*24)
         when 'minute' then floor((d2-d1)*1440)
         when 'second' then floor((d2-d1)*86400)
       end  
      ]';
  end get_diff;

  function get_diff2 (
    part in varchar2
   ,t1   in timestamp
   ,t2   in timestamp
  ) return varchar2 sql_macro ( scalar ) is
  begin
    return q'[       
       date_utils.get_diff(part, cast(t1 as date), cast(t2 as date))
      ]';
  end get_diff2;

end date_utils;
/
