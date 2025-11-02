class DocumentsController < ApplicationController
  before_action :set_document, only: %i[show reprocess]

  def index
    @search_query = params[:q].to_s.strip
    scope = @search_query.present? ? Document.search(@search_query) : Document.all

    @documents = scope.recent
    @document = Document.new
  end

  def show; end

  def create
    @document = Document.new(document_params)

    if @document.save
      redirect_to documents_path, notice: "Document uploaded successfully."
    else
      @search_query = params[:q].to_s.strip
      @documents = Document.recent
      render :index, status: :unprocessable_entity
    end
  end

  def reprocess
    @document.reprocess!
    redirect_to documents_path, notice: "Document reprocessing started."
  rescue StandardError => e
    redirect_to documents_path, alert: "Unable to reprocess document: #{e.message}"
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:file)
  end
end
