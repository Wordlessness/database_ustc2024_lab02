from django import forms

class BookSearchForm(forms.Form):
    book_name = forms.CharField(label='Book Name', max_length=100, required=False)
    author = forms.CharField(label='Author', max_length=50, required=False)