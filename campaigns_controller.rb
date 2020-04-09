class CampaignsController < ApplicationController

  def index
    campaigns = @current_user.campaigns
    if campaigns.present?
      render json: campaigns, each_serializer: CampaignSerializer
    else
      render json: { status: 404, message: "No records found." }
    end
  end

  def create
    campaign = Campaign.new(campaign_params)
    campaign.user = @current_user
    campaign.account = @current_user.account
    if campaign.save
      begin
        create_folloups campaign
        render json: { status: 200, message: "Campaign created successfully." }
      rescue => ex
        render json: {status: 404, message: ex.message}
      end
    else
        render json: {status: 404, message: "Something went wrong."}
    end
  end


  def start
    campaign = Campaign.find_by_id(params[:campaign_id])
    campaign.profiles.destroy_all
    cookie = request.headers["HTTP_LINKEDIN_COOKIE"]
    begin 
      @last_page_number = campaign.scrapping(cookie, params[:page_number])
    rescue Exception => e
      puts "exception found:#{e.exception}"
      render json:  { message: "Can't login to LinkedIn or no data found", status: 404 }
      return    
    end      
    @profiles = campaign.profiles.reload
  end  

  def campaign_operation
    case params[:action_type]
    when 'Delete'
      bulk_delete
    when 'End', 'Start', 'Pause'
      bulk_update
    else
      render json: {status: 404, message: 'Action doesn`t exist.'}
    end
  end

  private

  def bulk_delete
    if Campaign.delete(params[:ids].split(','))
      render json: { status: 200, message: "Campaigns Deleted Successfully."}
    else
      render json: { status: 404, message: "Something went wrong."}
    end
  end

  def bulk_update
    if Campaign.where(id: params[:ids].split(',')).update_all(status: params[:action_type])
      render json: { status: 200, message: "Campaigns Deleted Successfully."}
    else
      render json: { status: 404, message: "Something went wrong."}
    end
  end

  def create_folloups campaign
    params[:followUpsData].each do |record|
      campaignMessage =  CampaignMessage.new(description: record["message"])
      campaignMessage.campaign = campaign
      campaignMessage.save
    end
  end

  def campaign_params
    params.require(:campaign).permit(:url, :description, :followUpsData)
  end
end
