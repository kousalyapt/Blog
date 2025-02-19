class ArticlesController < ApplicationController

 # http_basic_authenticate_with name: "kous", password: "secret", except: [:index, :show]
  before_action :authenticate_user!
  
  def index
      if params[:query].present?
        @articles = Article.where('title LIKE ?', "%#{params[:query]}%")        
      else
        @articles = Article.all        
      end

      @articles = @articles.page(params[:page]).per(5)
    
  end

  def archive
    @archived_articles = Article.where(status: "archived").page(params[:page]).per(5)
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to root_path, status: :see_other
  end

  private
    def article_params
      params.require(:article).permit(:title, :body, :status, documents: [])
    end
end
