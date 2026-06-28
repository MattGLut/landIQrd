module Admin
  class ConversationsController < BaseController
    def index
      @conversations = Conversation.includes(:participants, :work_order, :messages).order(updated_at: :desc).page(params[:page]).per(PER_PAGE)
    end

    def show
      @conversation = Conversation.find(params[:id])
      @messages = @conversation.messages.includes(:author).order(:created_at)
    end
  end
end
