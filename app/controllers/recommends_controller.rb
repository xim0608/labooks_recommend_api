class RecommendsController < ApplicationController
  # /recommend/<int:book_id>
  # return json: [{name: , image_url} * 4]

  def show
    books_id = JSON.parse(Redis.current.get("books/sparse_recommends/#{params[:id]}"))
    sleep(2)
    books = Book.where(id: books_id)
    render json: books
  end
end
