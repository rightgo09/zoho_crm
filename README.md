[![Build Status](https://travis-ci.org/rightgo09/zoho_crm.png?branch=master)](https://travis-ci.org/rightgo09/zoho_crm)
[![Coverage Status](https://coveralls.io/repos/rightgo09/zoho_crm/badge.png?branch=master)](https://coveralls.io/r/rightgo09/zoho_crm?branch=master)
[![Dependency Status](https://gemnasium.com/rightgo09/zoho_crm.png)](https://gemnasium.com/rightgo09/zoho_crm)
[![Code Climate](https://codeclimate.com/github/rightgo09/zoho_crm.png)](https://codeclimate.com/github/rightgo09/zoho_crm)

zoho_crm gem
=============================

zoho_crm gem is a library to read, update and delete data in Zoho CRM.

https://www.zoho.com/crm/help/api/

## Support Modules

* Lead
* Account
* Contact
* Potential
* Campaign
* Case
* Solution
* Product
* PriceBook
* Quote
* Invoice
* SalesOrder
* Vendor
* PurchaseOrder
* Event
* Task
* Call

## Installation

Add this line to your application's Gemfile:

    gem 'zoho_crm'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zoho_crm

## Usage

### Get the token

You can get the token to use Zoho CRM API from the "Zoho CRM API" section available here:

https://crm.zoho.com/crm/ShowSetup.do?tab=developerSpace&subTab=api

### Setup Token

Before accessing Zoho data, you must first configure the access token.

    require "zoho_crm"
    ZohoCrm.token = "xxxxxxxxxxxxxxxx"

### Reading Data

This gem supports below methods:

* get_my_records
 * https://www.zoho.com/crm/help/api/getmyrecords.html
* get_records
 * https://www.zoho.com/crm/help/api/getrecords.html
* get_record_by_id
 * https://www.zoho.com/crm/help/api/getrecordbyid.html
* get_cv_records
 * https://www.zoho.com/crm/help/api/getcvrecords.html
* get_search_records
 * https://www.zoho.com/crm/help/api/getsearchrecords.html
* get_search_records_by_pdc
 * https://www.zoho.com/crm/help/api/getsearchrecordsbypdc.html
* get_related_records
 * https://www.zoho.com/crm/help/api/getrelatedrecords.html

#### get_record_by_id

    results = ZohoCrm::Potential.get_record_by_id(id: 11111111111111111)
    #=> results: [{"POTENTIALID"=>"11111111111111111",...}]

#### get_search_records

    results = ZohoCrm::Potential.get_search_records(
        select_columns: ["Potential Name", "Potential Owner"],
        search_condition: {"Potential Name" => {"contains" => "foo"}},
    )
    # request: {"selectColumns"=>"Potentials(Potential Name,Potential Owner)",
                "searchCondition"=>"(Potential Name|contains|*foo*)"}

The result data class is a Hash, so you can read the content like below:

    results[0]["Potential Name"]

If you want to get all data including null content, you should do like below:

    ZohoCrm::Potential.get_record_by_id(id: 11111111111111111, select_columns: "All", new_format: 2)

## Contributing

1. Fork it ( http://github.com/rightgo09/zoho_crm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
