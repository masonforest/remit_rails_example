class PaymentsController < ApplicationController

  def show
    @payment = Payment.find(params[:id])
    @response =  Remit::PipelineResponse.new(
      request.fullpath,
      params,
      remit
    )
  @pay_response=fps_pay(@payment.amount,@response.tokenID)
  
  end

  def new
    @payment = Payment.new
  end
  def edit
    @payment = Payment.find(params[:id])
  end

  def create
    @payment = Payment.new(params[:payment])
      if @payment.save
        redirect_to fps_payment_url(
          @payment.id,
          params[:payment][:amount],
          payment_url(@payment)
        )
        	
      else
        render :action => "new" 
      end
  end
  private
  def fps_pay(amount,sender_token)
    request = Remit::InstallPaymentInstruction::Request.new(
      :payment_instruction => "MyRole == 'Caller' orSay 'Role does not match';",
      :caller_reference => Time.now.to_i.to_s,
      :token_friendly_name => "Caller Token",
      :token_type => "Unrestricted"
    )
    caller_token = remit.install_payment_instruction(request).install_payment_instruction_result.token_id 


    request = Remit::InstallPaymentInstruction::Request.new(
      :payment_instruction => "MyRole == 'Recipient' orSay 'Role does not match';",
      :caller_reference => Time.now.to_i.to_s,
      :token_friendly_name => "Recipient Token",
      :token_type => "Unrestricted"
    )

    recipient_token = remit.install_payment_instruction(request).install_payment_instruction_result.token_id 




    install_caller_response = remit.install_payment_instruction(request)
      request = Remit::Pay::Request.new(
        :caller_token_id => caller_token,
        :recipient_token_id => recipient_token, 
        :sender_token_id => sender_token,
        :transaction_amount        => Remit::RequestTypes::Amount.new(:currency_code => 'USD', :amount => amount),  
        :charge_fee_to => "Recipient",
        :caller_reference => Time.now.to_i.to_s
    )

    remit.pay(request).inspect

    end
    def fps_payment_url(id,amount,return_url)
      remit.get_single_use_pipeline(
        :caller_reference => (0...8).map{65.+(rand(25)).chr}.join,
        :transaction_amount => "8.00",
        :return_url => return_url
      ).url
    end
  def remit
   @remit ||= begin
   sandbox = !Rails.env.production?
   Remit::API.new(FPS_ACCESS_KEY, FPS_SECRET_KEY, sandbox)
  end
end 
end
