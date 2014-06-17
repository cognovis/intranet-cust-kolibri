-- 
-- packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.2.0.2-4.0.2.0.3.sql
-- 
-- Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2012-04-07
-- @cvs-id $Id$
--

SELECT acs_log__debug('/packages/intranet-cust-kolibri/sql/postgresql/upgrade/upgrade-4.0.2.0.2-4.0.2.0.3.sql','');


-- We need to update the german customers
update im_companies set tax_classification = 42050 where company_id in (select company_id from im_offices where address_country_code = 'de') and company_type_id in (54,55,57,10244,10000006,10000008,10000009);

-- Worldwide customers
update im_companies set tax_classification = 42040 where company_id in (select company_id from im_offices where address_country_code != 'de') and company_type_id in (54,55,57,10244,10000006,10000008,10000009);

-- EU customers
update im_companies set tax_classification = 42030 where company_id in (select company_id from im_offices where address_country_code in ('be','dk','ee','fi','fr','el','gb','ie','it','lv','lt','lu','mt','nl','at','pl','pt','ro','se','sk','si','es','cz','hu','cy')) and company_type_id in (54,55,57,10244,10000006,10000008,10000009) and vat_number is not null;

-- German providers
update im_companies set tax_classification = 42000 where company_id in (select company_id from im_offices where address_country_code = 'de') and company_type_id in (56,58,59,10000300);

-- German small pbusiness providers
update im_companies set tax_classification = 42001 where company_id in (select company_id from im_offices where address_country_code = 'de') and company_type_id =10000301;

-- Wordlwide Providers
update im_companies set tax_classification = 42020 where company_id in (select company_id from im_offices where address_country_code != 'de') and company_type_id in (56,58,59,10000300,10000301);

-- EU Providers
update im_companies set tax_classification = 42010 where company_id in (select company_id from im_offices where address_country_code in ('be','dk','ee','fi','fr','el','gb','ie','it','lv','lt','lu','mt','nl','at','pl','pt','ro','se','sk','si','es','cz','hu','cy')) and company_type_id in (56,58,59,10000300,10000301);


-- Set default vat for all companies
update im_companies set default_vat = aux_int1 from im_categories where category_id = tax_classification;