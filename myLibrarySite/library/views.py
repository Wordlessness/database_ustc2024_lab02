# Create your views here.
from django.shortcuts import render
from django.http import HttpResponse
from django.db import connection
from django.http import JsonResponse
import json
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.db import connection
import base64


def home(request):
    context = simulated_date(request)
    return render(request, 'library/home.html', context)


def borrow_search(request, user_id):
    query = """
        SELECT borrow.book_id, borrow.borrow_date, borrow.return_date, borrow.return_ddl, borrow.if_default,
               book.title, book.author 
        FROM borrow 
        JOIN book ON borrow.book_id = book.bid 
        WHERE reader_id LIKE %s
    """
    params = [f'%{user_id}%']
    borrows = []
    with connection.cursor() as cursor:
        cursor.execute(query, params)
        rows = cursor.fetchall()
        for row in rows:
            borrow = {
                'title': row[5],  # 对应 book.title
                'author': row[6],  # 对应 book.author
                'borrow_date': row[1],
                'return_date': row[2],
                'return_ddl': row[3],
                'is_default': row[4]
            }
            borrows.append(borrow)
    return render(request, 'library/borrow_search.html', {'borrows': borrows})

def reserve_search(request, user_id):
    query = """
        SELECT reserve.book_id, reserve.reserve_date, reserve.take_date, reserve.reserve_ddl, 
               book.title, book.author 
        FROM reserve
        JOIN book ON reserve.book_id = book.bid 
        WHERE reader_id LIKE %s
    """
    params = [f'%{user_id}%']
    reserves = []
    with connection.cursor() as cursor:
        cursor.execute(query, params)
        rows = cursor.fetchall()
        for row in rows:
            reserve = {
                'title': row[4],  # 对应 book.title
                'author': row[5],  # 对应 book.author
                'reserve_date': row[1],
                'take_date': row[2],
                'reserve_ddl': row[3],
            }
            reserves.append(reserve)
    return render(request, 'library/reserve_search.html', {'reserves': reserves})

def search_books(request):
    book_name = request.GET.get('book_name', '')
    author = request.GET.get('author', '')

    query = "SELECT * FROM book WHERE 1=1"
    params = []

    if book_name:
        query += " AND title LIKE %s"
        params.append(f'%{book_name}%')

    if author:
        query += " AND author LIKE %s"
        params.append(f'%{author}%')

    books = []
    with connection.cursor() as cursor:
        cursor.execute(query, params)
        rows = cursor.fetchall()
        for row in rows:
            book = {
                'bid': row[0],
                'title': row[1],
                'author': row[2],
                'cover': base64.b64encode(row[3]).decode('utf-8') if row[3] else None,
                'reserve_queue': row[4],
                'borrow_times': row[5],
                'books_available': row[6],
                'books_total': row[7]
            }
            books.append(book)

    return render(request, 'library/search_result.html', {'books': books})


def date_update(request):
    if request.method == 'POST':
        delta = request.POST.get('delta')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('date_update', [delta, status])
            cursor.execute("SELECT @_date_update_1")
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "日期改变成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def simulated_date(request):
    with connection.cursor() as cursor:
        cursor.execute("SELECT var_value FROM global_var WHERE var_name = %s", ['cur_date'])
        row = cursor.fetchone()
        simulated = row[0] if row else None

    context = {
        'simulated_date': simulated
    }
    return context


def login_judge(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_id = data.get('user_id')
        password = data.get('password')
        if_reader = False if user_id and user_id[0] == 'm' else True
        name = "李华"

        status = 0
        with connection.cursor() as cursor:
            cursor.callproc('user_login', [user_id, password, if_reader, status, name])
            cursor.execute("SELECT @_user_login_3, @_user_login_4")  # 3 是 pstatus 参数的位置 (0-indexed)
            result = cursor.fetchone()
            status = result[0]
            name = result[1]

        if status == 0:
            return JsonResponse({"status": "success", "message": "登录成功~",
                                 "user_id": user_id, "name": name, "if_reader": if_reader})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的学生呢"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的图书管理员呢"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀,您还没有设置密码呢,点击找回密码来设置密码吧"})
        elif status == 5:
            return JsonResponse({"status": "error", "message": "密码错误,请重试"})

    return render(request, 'library/login.html')


def login_reader(request):
    user_id = request.GET.get('user_id')
    name = request.GET.get('name')
    return render(request, 'library/reader.html', {'user_id': user_id, 'name': name})


def borrow_book(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        id = request.POST.get('ID')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('borrow_book', [id, title, author, status])
            cursor.execute("SELECT @_borrow_book_3")  # 4 是 pstatus 参数的位置 (0-indexed)
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您还在违约哦, 先把逾期的书还了吧"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,您已经到达借阅上限了哦, 先去还几本书吧"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀,没有剩余的书了哦,快去试试预约吧"})
        elif status == 5:
            return JsonResponse({"status": "error", "message": "诶呀,您今天已经借过这本书了哦"})
        elif status == 6:
            return JsonResponse({"status": "error", "message": "诶呀,您已经借过这本书并且还没有还哦, 看你已经借的那本就好啦"})
        elif status == 7:
            return JsonResponse({"status": "error", "message": "诶呀,这本书不存在哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def return_book(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        id = request.POST.get('ID')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('return_book', [id, title, author, status])
            cursor.execute("SELECT @_return_book_3")  # 4 是 pstatus 参数的位置 (0-indexed)
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您根本没有借这本书哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def reserve_book(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        id = request.POST.get('ID')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('reserve_book', [id, title, author, status])
            cursor.execute("SELECT @_reserve_book_3")  # 4 是 pstatus 参数的位置 (0-indexed)
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您还在违约哦, 先把逾期的书还了吧"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,您今天已经预约过这本书了哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def delete_reserve(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        id = request.POST.get('ID')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('delete_reserve', [id, title, author, status])
            cursor.execute("SELECT @_delete_reserve_3")  # 4 是 pstatus 参数的位置 (0-indexed)
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您没有预约哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def login_manager(request):
    user_id = request.GET.get('user_id')
    name = request.GET.get('name')
    return render(request, 'library/manager.html', {'user_id': user_id, 'name': name})


@csrf_exempt
def add_book_new(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        cover = request.FILES['cover'].read() if 'cover' in request.FILES else None
        num = int(request.POST.get('num'))
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('add_book_new', [title, author, cover, num, status])
            cursor.execute("SELECT @_add_book_new_4")  # 4 是 pstatus 参数的位置 (0-indexed)
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您要插入的书已经存在了,快去试试'添加书籍(已有)'吧"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,图书馆满了呢,暂时不能加新书了"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀,添加书籍的本数必须为正哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def add_book_old(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        num = int(request.POST.get('num'))
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('add_book_old', [title, author, num, status])
            cursor.execute("SELECT @_add_book_old_3")
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您要插入的书还不存在呢,快去试试 添加书籍(新书) 吧"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,添加书籍的本数必须为正哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def delete_book_some(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        num = int(request.POST.get('num'))
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('delete_book_some', [title, author, num, status])
            cursor.execute("SELECT @_delete_book_some_3")
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍删除成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您要删除的书还不存在呢 "})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,删除书籍的本数必须为正哦"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀,没有那么多书让你删哦"})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def delete_book_all(request):
    if request.method == 'POST':
        title = request.POST.get('title')
        author = request.POST.get('author')
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('delete_book_all', [title, author, status])
            cursor.execute("SELECT @_delete_book_all_2")
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍删除成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您要删除的书还不存在呢 "})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def get_verification_code(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_id = data.get('reset_user_id')
        tel = data.get('reset_tel')
        if_reader = False if user_id[0] == 'm' else True
        status = 0
        verification_code = None

        with connection.cursor() as cursor:
            cursor.callproc('get_verify_code', [user_id, tel, if_reader, verification_code, status])
            cursor.execute("SELECT @_get_verify_code_3, @_get_verify_code_4")  # 获取 pstatus 和 return_code
            result = cursor.fetchone()
            status = result[1]
            verification_code = result[0]

        if status == 0:
            return JsonResponse({"status": "success", "verification_code": verification_code})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的学生呢"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的图书管理员呢"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀, 您的电话号码似乎不匹配呢"})

    return JsonResponse({"status": "error", "message": "无效的请求"})


def update_book(request):
    if request.method == 'POST':
        OriginTitle = request.POST.get('OriginTitle')
        OriginAuthor = request.POST.get('OriginAuthor')
        NewTitle = request.POST.get('NewTitle') or None
        NewAuthor = request.POST.get('NewAuthor') or None
        NewCover = request.FILES['NewCover'].read() if 'NewCover' in request.FILES else None
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('update_book', [OriginTitle, OriginAuthor, NewTitle, NewAuthor, NewCover, status])
            cursor.execute("SELECT @_update_book_5")
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "书籍添加成功"})
        elif status == 1:
            return JsonResponse({"status": "error", "message": "系统错误，请稍后重试"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您要修改的书还不存在呢 "})

    return JsonResponse({"status": "error", "message": "无效的请求方法"})


def verify_return_code(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_id = data.get('reset_user_id')
        tel = data.get('reset_tel')
        verify_code = data.get('verify_code')
        if_reader = False if user_id[0] == 'm' else True
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('verify_return_code', [user_id, tel, verify_code, if_reader, status])
            cursor.execute("SELECT @_verify_return_code_4")  # 获取 pstatus
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的学生呢"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀,您好像不是这个学校的图书管理员呢"})
        elif status == 4:
            return JsonResponse({"status": "error", "message": "诶呀, 您的电话号码似乎不匹配呢"})
        elif status == 5:
            return JsonResponse({"status": "error", "message": "诶呀, 您的验证码不对呢"})

    return JsonResponse({"status": "error", "message": "无效的请求"})


def reset_password(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        user_id = data.get('reset_user_id')
        password1 = data.get('password1')
        password2 = data.get('password2')
        if_reader = False if user_id[0] == 'm' else True
        status = 0

        with connection.cursor() as cursor:
            cursor.callproc('reset_password', [user_id, if_reader, password1, password2, status])
            cursor.execute("SELECT @_reset_password_4")  # 获取 pstatus
            status = cursor.fetchone()[0]

        if status == 0:
            return JsonResponse({"status": "success", "message": "密码重置成功~"})
        elif status == 2:
            return JsonResponse({"status": "error", "message": "诶呀, 您两次输入的密码似乎不一样呢"})
        elif status == 3:
            return JsonResponse({"status": "error", "message": "诶呀, 您的密码长度不在8-16位之间呢"})

    return JsonResponse({"status": "error", "message": "无效的请求"})
