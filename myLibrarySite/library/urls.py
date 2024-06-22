from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('search/', views.search_books, name='search_books'),
    path('reset-password/', views.reset_password, name='reset_password'),
    path('get-verification-code/', views.get_verification_code, name='get_verification_code'),
    path('verify-return-code/', views.verify_return_code, name='verify_return_code'),
    path('login-judge/', views.login_judge, name='login_judge'),
    path('login/reader/', views.login_reader, name='login_reader'),
    path('login/manager/', views.login_manager, name='login_manager'),
    path('add-book-new/', views.add_book_new, name='add_book_new'),
    path('add-book-old/', views.add_book_old, name='add_book_old'),
    path('delete-book-some/', views.delete_book_some, name='delete_book_some'),
    path('delete-book-all/', views.delete_book_all, name='delete_book_all'),
    path('update-book/', views.update_book, name='update_book'),
    path('date-update/', views.date_update, name='date_update'),
    path('simulated-date/', views.simulated_date, name='simulated_date'),
    path('borrow-book/', views.borrow_book, name='borrow_book'),
    path('return-book/', views.return_book, name='return_book'),
    path('reserve-book/', views.reserve_book, name='reserve_book'),
    path('delete-reserve/', views.delete_reserve, name='delete_reserve'),
    path('borrow-search/<str:user_id>/', views.borrow_search, name='borrow_search'),
    path('reserve-search/<str:user_id>/', views.reserve_search, name='reserve_search'),
]