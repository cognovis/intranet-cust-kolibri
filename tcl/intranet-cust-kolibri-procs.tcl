# packages/intranet-cust-kolibri/tcl/intranet-cust-kolibri-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    Kolibri Custom Procs
    
    @author  (kolibri@ubuntu.localdomain)
    @creation-date 2011-10-07
    @cvs-id $Id$
}

ad_proc -public -callback im_invoice_before_update -impl kolibri_set_vars {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Set the invoice variables needed by Kolibri
} {

    # ------------------------------------------------------------------
    # We need the quote number, the quote date and the delivery date
    # ------------------------------------------------------------------

    # Upvar two levels as there is the callback level in between
    upvar 2 quote_no quote_no
    upvar 2 quote_date quote_date
    upvar 2 delivery2_date delivery2_date
    upvar 2 delivery_date end_date
    upvar 2 company_project_nr company_project_nr

    set project_id [db_string project_id "select project_id from im_costs where cost_id = :object_id" -default ""]
    if {"" != $project_id} {
	if {[db_0or1row quote_information "select company_project_nr,cost_name, effective_date, end_date from im_costs c, im_projects p where p.project_id = :project_id and p.project_id = c.project_id and cost_type_id = 3702 order by effective_date desc limit 1"]} {
	    set quote_no $cost_name
	    set quote_date [lc_time_fmt $effective_date %q]
	    set delivery2_date [lc_time_fmt $end_date "%q"]
	}
    }
} 

ad_proc -public intranet_kolibri_send_provider_bills {
    {-start_date ""}
} {
    Sends out the provider bills from Purchase orders which are generated since the start_date
} {
    set bill_type_ids [im_sub_categories 3704]
    set bill_ids [db_list provider_bills "select cost_id from im_costs where effective_date >= to_date(:start_date,'YYYY-MM-DD') and cost_type_id in ([template::util::tcl_to_sql_list $bill_type_ids])"] 
    foreach invoice_id $bill_ids {
        im_invoice_send_invoice_mail -from_addr ts@kolibri-kommunikation.com -cc_addr st@kolibri-kommunikation.com -invoice_id $invoice_id
    }
}


ad_proc -public intranet_kolibri_generate_provider_bills {
    -end_date:required
    {-cost_status_id "3804"}
    -start_date:required
} {
    Generate the provider bills from Purchase orders which are generated until end_date
} {
    set po_type_ids [im_sub_categories [im_cost_type_po]]
    set po_ids [db_list purchase_orders "select cost_id from im_costs where cost_status_id = :cost_status_id and effective_date <= to_date(:end_date,'YYYY-MM-DD') and cost_type_id in ([template::util::tcl_to_sql_list $po_type_ids]) and effective_date >= to_date(:start_date,'YYYY-MM-DD')"]
    foreach cost_id $po_ids {
        set invoice_id [im_invoice_copy_new -source_invoice_ids $cost_id -target_cost_type_id 3704]
	
        # Update the purchase order to status paid
        db_dml update_invoice "update im_costs set cost_status_id = [im_cost_status_paid] where cost_id = $cost_id"

        im_invoice_send_invoice_mail -from_addr ts@kolibri-kommunikation.com -cc_addr st@kolibri-kommunikation.com -invoice_id $invoice_id
	
        # Update the provider bill to status outstanding
        db_dml update_invoice "update im_costs set cost_status_id = [im_cost_status_outstanding] where cost_id = $invoice_id"	
    }
}



ad_proc -public -callback im_project_after_update -impl kolibri_purchase_order_status {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    If a project is closed, generate the provider bills for the purchase orders.
} {
    set closed_ids [im_sub_categories 81]
    if {[lsearch $closed_ids $status_id]>-1} {
        #  find the purchase order for the project and update them
        set cost_types [im_sub_categories [im_cost_type_po]]
        set purchase_order_ids [db_list purchase_orders "select distinct cost_id from im_costs c, acs_rels ar
              where c.cost_id = ar.object_id_two and ar.object_id_one = :object_id
              and cost_type_id in ([template::util::tcl_to_sql_list $cost_types]) and cost_status_id = 3802"]

        foreach cost_id $purchase_order_ids {
	        # Double click protection or against the same cost_id
            # twice in the list. Therefore check the current cost_status_id if
            # it is not marked as paid
            set cost_status_id [db_string cost_status_id "select cost_status_id from im_costs where cost_id = :cost_id" -default ""]
            if {3802 == $cost_status_id} {
                # Check if we have a provider bill attached to it
                # Add this as a potential later change
                set invoice_id [im_invoice_copy_new -source_invoice_ids $cost_id -target_cost_type_id 3704]
		
                # Update the purchase order to status paid
                db_dml update_invoice "update im_costs set cost_status_id = [im_cost_status_paid] where cost_id = $cost_id"
		
                im_invoice_send_invoice_mail -from_addr ts@kolibri-kommunikation.com -cc_addr st@kolibri-kommunikation.com -invoice_id $invoice_id
		
                # Update the provider bill to status outstanding
                db_dml update_invoice "update im_costs set cost_status_id = [im_cost_status_outstanding] where cost_id = $invoice_id"	
            }
        }
    }

   # Update the modification date
    db_dml update "update acs_objects set last_modified = now() where object_id = :object_id"

}

ad_proc -public -callback im_project_after_update -impl kolibri_update_cost_center {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Update the cost center when a project is saved
} {
    # get the type
    if {$type_id eq ""} {
	    set type_id [db_string type "select project_type_id from im_projects where project_id = :object_id"]
    }
    
    switch $type_id {
	    10000014 { set cost_center_id 140731 }
        10000011 { set cost_center_id 140733 }
        10000099 { set cost_center_id 140737 }
        10000097 { set cost_center_id 140725 }
        10000010 { set cost_center_id 140727 }
        10000124 { set cost_center_id 140723 }
        86 { set cost_center_id 140725 }
        10000007 { set cost_center_id 12388 }
        default { set cost_center_id 140729 }
    }
    
    # Update the cost center
    db_dml update_cost_center "update im_projects set cost_center_id = :cost_center_id where project_id = :object_id"
}

ad_proc -public -callback im_project_after_create -impl kolibri_update_cost_center {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Update the cost center when a project is saved
} {
    # get the type
    if {$type_id eq ""} {
	    set type_id [db_string type "select project_type_id from im_projects where project_id = :object_id"]
    }
    
    switch $type_id {
	    10000014 { set cost_center_id 140731 }
        10000011 { set cost_center_id 140733 }
        10000099 { set cost_center_id 140737 }
        10000097 { set cost_center_id 140725 }
        10000010 { set cost_center_id 140727 }
        10000124 { set cost_center_id 140723 }
        86 { set cost_center_id 140725 }
        10000007 { set cost_center_id 12388 }
        default { set cost_center_id 140729 }
    }
    
    # Update the cost center
    db_dml update_cost_center "update im_projects set cost_center_id = :cost_center_id where project_id = :object_id"
}

ad_proc -public -callback im_company_after_update -impl kolibri_update_vat_and_tax {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    If a company is saved automatically determine the VAT and tax classification
} {
    set country_code [db_string address "select address_country_code from im_offices o, im_companies c where c.main_office_id=o.office_id and c.company_id = :object_id"]
    set company_type_id $type_id
    # Figure out the country
    switch $country_code {
	de {
	    # this is a german company
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		# Differentiate between large and small
		if {$type_id eq 10000301} {
		    set vat 0
		    set vat_type 42001
		} else {
		    set vat 19
		    set vat_type 42000
		}
	    } else {
		set vat 19
		set vat_type 42050
	    }
	}
	be - bg - cz - dk - ee - ie - el - es - fr - it - cy - lv - lt - lu - hu - mt - nl - at - pl - pt - ro - si - sk - fi - se - uk - gb {
	    # European
	    set vat 0
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		# Enforce the provide type
		set company_type_id [im_company_type_provider]
		set vat_type 42010
	    } else {
		set vat_type 42030
	    } 
	} 
	default {
	    # ROW
	    set vat 0
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		set company_type_id [im_company_type_provider]
		set vat_type 42020
	    } else {
		set vat_type 42040
	    } 
	}
    }

    # Set default payment terms
    set payment_term_id [db_string payment_term "select payment_term_id from im_companies where company_id = :object_id" -default ""]
    if {"" == $payment_term_id} {
	set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	if {$provider_p} {
	    # Providers have 30 day payment terms
	    set payment_term_id 80130
	} else {
	    set payment_term_id 80114
	} 
    }

    # update the company
    db_dml update_company "update im_companies set company_type_id = :company_type_id, default_vat = :vat , vat_type_id = :vat_type, payment_term_id = :payment_term_id where company_id = :object_id"
    ns_log Notice "$object_id :: $payment_term_id -- Kolibri:: $country_code :: $vat :: $vat_type"
    db_dml update_company "update im_companies set company_type_id = :company_type_id, default_vat = :vat , vat_type_id = :vat_type, payment_term_id = :payment_term_id where company_id = :object_id"

    # Update the modification date
    db_dml update "update acs_objects set last_modified = now() where object_id = :object_id"

}

ad_proc -public -callback im_company_after_create -impl kolibri_update_vat_and_tax {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    If a company is saved automatically determine the VAT and tax classification
} {
    set country_code [db_string address "select address_country_code from im_offices o, im_companies c where c.main_office_id=o.office_id and c.company_id = :object_id"]
    set company_type_id $type_id
    # Figure out the country
    switch $country_code {
	de {
	    # this is a german company
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		# Differentiate between large and small
		if {$type_id eq 10000301} {
		    set vat 0
		    set vat_type 42001
		} else {
		    set vat 19
		    set vat_type 42000
		}
	    } else {
		set vat 19
		set vat_type 42050
	    }
	}
	be - bg - cz - dk - ee - ie - el - es - fr - it - cy - lv - lt - lu - hu - mt - nl - at - pl - pt - ro - si - sk - fi - se - uk - gb {
	    # European
	    set vat 0
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		# Enforce the provide type
		set company_type_id [im_company_type_provider]
		set vat_type 42010
	    } else {
		set vat_type 42030
	    } 
	} 
	default {
	    # ROW
	    set vat 0
	    set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	    if {$provider_p} {
		set company_type_id [im_company_type_provider]
		set vat_type 42020
	    } else {
		set vat_type 42040
	    } 
	}
    }

    # Set default payment terms
    set payment_term_id [db_string payment_term "select payment_term_id from im_companies where company_id = :object_id" -default ""]
    if {"" == $payment_term_id} {
	set provider_p [im_category_is_a $type_id [im_company_type_provider]]
	if {$provider_p} {
	    # Providers have 30 day payment terms
	    set payment_term_id 80130
	} else {
	    set payment_term_id 80114
	} 
    }

    # update the company
    ns_log Notice "Kolibri:: $country_code :: $vat :: $vat_type"
    db_dml update_company "update im_companies set company_type_id = :company_type_id, default_vat = :vat , vat_type_id = :vat_type, payment_term_id = :payment_term_id where company_id = :object_id"

    # Update the modification date
    db_dml update "update acs_objects set last_modified = now() where object_id = :object_id"

}

ad_proc -public intranet_kolibri_cleanup_invoices {
} {
    Cleanup invoices and add customer_contact_id
} {
    set invoice_ids [db_list invoices "select invoice_id from im_invoices where company_contact_id is null"]
    foreach invoice_id $invoice_ids {
	set cost_type_id [db_string cost_type_id "select cost_type_id from im_costs where cost_id = :invoice_id" -default 0]
	set invoice_or_quote_p [expr [im_category_is_a $cost_type_id [im_cost_type_invoice]] || [im_category_is_a $cost_type_id [im_cost_type_quote]] || [im_category_is_a $cost_type_id [im_cost_type_delivery_note]] || [im_category_is_a $cost_type_id [im_cost_type_interco_quote]] || [im_category_is_a $cost_type_id [im_cost_type_interco_invoice]]]
	
	if {$invoice_or_quote_p} {
	    # A Customer document
	    set customer_or_provider_join "ci.customer_id = c.company_id"
	} else {
	    # A provider document
	    set customer_or_provider_join "ci.provider_id = c.company_id"
	    
	    db_0or1row company_info "select primary_contact_id, accounting_contact_id from im_companies c, im_costs ci where ci.cost_id = :invoice_id and $customer_or_provider_join"
	    set company_contact_id $accounting_contact_id
	    if {"" == $company_contact_id} { 
		set company_contact_id $primary_contact_id 
	    }
	    if {"" != $company_contact_id} { 
		ds_comment "updating $invoice_id with $company_contact_id"
		db_dml update_company_contact "update im_invoices set company_contact_id = :company_contact_id where invoice_id = :invoice_id"
	    } else {
		ds_comment "Cant update $invoice_id with a company_contact_id"
	    }
	}
    }
}

ad_proc -public intranet_kolibri_cleanup_customers {
} {
    Find all customers without a primary contact and assign the sole company contact to it, if there is one
} {
    set company_ids [db_list company "select company_id from im_companies where primary_contact_id is null"]
    foreach company_id $company_ids {
	set users [db_list user "
select DISTINCT
u.user_id
from
cc_users u,
group_distinct_member_map m,
acs_rels ur
where u.member_state = 'approved'
and u.user_id = m.member_id
and m.group_id in ([im_customer_group_id], [im_freelance_group_id])
and u.user_id = ur.object_id_two
and ur.object_id_one = :company_id
and ur.object_id_one != 0
"]

if {[llength $users] ==1} {
    db_dml update_primary_contact "update im_companies set primary_contact_id = :users where company_id = :company_id"
} else {
    set company_name [db_string name "select company_name from im_companies where company_id = :company_id"]
    acs_mail_lite::send -send_immediately -from_addr [ad_admin_owner] -to_addr [ad_admin_owner] -subject "Missing primary contact for company_id $company_id" -body "We could not find and assign a primary contact to the company <a href=[export_vars -base "[ad_url]/intranet/companies/view" -url {company_id}]>$company_name</a>. Please assign this company a contact person otherwise you wont be able to send any form of invoice" -mime_type "text/html"
}

}
}

ad_proc -public intranet_kolibri_created_bills {
    {-start_date:required}
} {
    Find out the bills which have a PDF generated for them and return one combined PDF with all of them
} {
    set bill_type_ids [im_sub_categories 3704]
    set bill_ids [db_list provider_bills "select cost_id from im_costs where effective_date >= to_date(:start_date,'YYYY-MM-DD') and cost_type_id in ([template::util::tcl_to_sql_list $bill_type_ids]) order by effective_date asc, provider_id"] 

    set filenames [list]
    foreach invoice_id $bill_ids {
	# Find out if we have a PDF generated already
	set invoice_nr [db_string name "select invoice_nr from im_invoices where invoice_id = :invoice_id"]
	set item_id [content::item::get_id_by_name -name ${invoice_nr}.pdf -parent_id $invoice_id]
	if {"" != $item_id} {
	    set filename [fs::publish_object_to_file_system  -object_id $item_id -path /tmp]
	    lappend filenames $filename
	}
    }

    # Generate the pdf
    set pdf_info [intranet_oo::join_pdf -filenames $filenames -no_import]
    
    # Delete the original PDFs
    foreach filename $filenames {
	file delete $filename
    }
   
    ds_comment "$pdf_info"
    set outputheaders [ns_conn outputheaders]
    ns_set cput $outputheaders "Content-Disposition" "attachment; filename=Bills.pdf"
    ns_returnfile 200 [lindex $pdf_info 0] [lindex $pdf_info 1]
}


ad_proc -public -callback im_invoice_after_create -impl aa_kolibri_update_cost_center {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Update the cost center of the invoice with the one from the project
} {
    set cost_center_id [db_string cost_center "select p.cost_center_id from im_projects p,im_costs c where p.project_id = c.project_id and c.cost_id = :object_id" -default ""]

    if {"" != $cost_center_id} {
	# Update the cost center
	db_dml update "update im_costs set cost_center_id = :cost_center_id where cost_id = :object_id"
    }
}


ad_proc -public -callback im_invoice_after_update -impl 00_kolibri_update_cost_center {
    {-object_id:required}
    {-status_id ""}
    {-type_id ""}
} {
    Update the cost center of the invoice with the one from the project
} {
    # disabled
    set cost_center_id [db_string cost_center "select p.cost_center_id from im_projects p,im_costs c where p.project_id = c.project_id and c.cost_id = :object_id" -default ""]
    
    if {"" != $cost_center_id} {
	# Update the cost center
	db_dml update "update im_costs set cost_center_id = :cost_center_id where cost_id = :object_id"
    }

    # Update the modification date
    db_dml update "update acs_objects set last_modified = now() where object_id = :object_id"
}

ad_proc -public -callback im_project_on_submit -impl aaa_kolibri_check_for_logged_hours {
    {-object_id:required}
    {-form_id:required}

} {
    Check if the project has logged hours, otherwise do not allow to close the project
} {

    set status_id [template::element::get_value $form_id project_status_id]
    upvar error_field error_field
    upvar error_message error_message
    
    set closed_ids [im_sub_categories 81]
    if {[lsearch $closed_ids $status_id]>-1} {
        # Check that we have logged hours
        set logged_hours_p [db_string logged_hours "select 1 from im_hours where project_id = :object_id limit 1" -default 0]

        ns_log Notice "Logger. $logged_hours_p"
        if {!$logged_hours_p} {
            set error_field "project_status_id"
            set error_message "[_ intranet-cust-kolibri.lt_Your_need_logged_hours_for_close]"
        }   
    }
}

