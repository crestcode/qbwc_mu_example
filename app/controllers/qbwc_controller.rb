class QbwcController < ApplicationController
  require 'Quickbooks'
  require 'rexml/document'
  protect_from_forgery :except => :api

  def qwc
    qwc = <<-QWC
    <QBWCXML>
    <AppName>QBWC Multiuser Example</AppName>
    <AppID>QB</AppID>
    <AppURL>http://localhostmac:3000/apis/quickbooks/api</AppURL>
    <AppDescription>Rails-Quickbooks Integration</AppDescription>
    <AppSupport>http://localhostmac:3000/</AppSupport>
    <UserName>test</UserName>
    <OwnerID>#{QBWC.owner_id}</OwnerID>
    <FileID>{90A44FB5-33D9-4815-AC85-BC87A7E7D1EB}</FileID>
    <QBType>QBPOS</QBType>
    <Style>Document</Style>
    <Scheduler>
      <RunEveryNMinutes>5</RunEveryNMinutes>
    </Scheduler>
    </QBWCXML>
    QWC
    send_data qwc, :filename => 'qbwc_mu.qwc'
  end

  def api

    # increase entity_expansion_text_limit during web connector sessions for large (25+ items) pulls
    REXML::Document.entity_expansion_text_limit = 5_000_000

    # respond successfully to a GET which some versions of the Web Connector send to verify the url
    if request.get?
      render :nothing => true
      return
    end

    if params["Envelope"]["Body"].keys.first =="authenticate"
      QBWC.add_job("test", :import_vendors) do
        '
        <?qbposxml version="3.0"?>
        <QBPOSXML>
      <QBPOSXMLMsgsRq onError="stopOnError">
            <ItemInventoryQueryRq>
          </ItemInventoryQueryRq>
        </QBPOSXMLMsgsRq>
        </QBPOSXML>
      '
      end

      QBWC.jobs["test"][:import_vendors].set_response_proc do |qbxml|
        puts "====================Dumping QBXML====================="
        puts qbxml
      end
    end

    req = request
    puts "========== #{ params["Envelope"]["Body"].keys.first}  =========="
    res = QBWC::SoapWrapper.route_request(req)
    render :xml => res, :content_type => 'text/xml'
  end

end