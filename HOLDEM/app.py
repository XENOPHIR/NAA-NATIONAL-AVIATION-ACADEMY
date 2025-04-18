import pyodbc
import random
import string
import os
from werkzeug.utils import secure_filename
from flask import Flask, render_template, Blueprint, request, redirect, url_for, session, flash, jsonify
from forms import RegistrationForm, LoginForm 
from werkzeug.security import generate_password_hash, check_password_hash
from flask_mail import Mail, Message

app = Flask(__name__)
app.secret_key = b'\xfd\xe1O\x98\xb3\xd8\xc7z\x1d\xcf9\x93\x1b\xd6u\xc8\xf9\xc7I\xb8\xf3l\xd2\xf0'

# SMTP Configuration
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'edu.notexxx@gmail.com'
app.config['MAIL_PASSWORD'] = 'ultl mwsi dzvb wjyy'

mail = Mail(app)

# DATABASE CONNECTION
def get_db_connection():
    return None 


# HELPER FUNCTIONS
def is_authenticated():
    return 'user_id' in session

def is_authorized(required_role):
    if not is_authenticated():
        return False
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT r.RoleName
        FROM Users u
        JOIN Roles r ON u.RoleID = r.RoleID
        WHERE u.UserID = ?
        """,
        (session['user_id'],)
    )
    role = cursor.fetchone()
    conn.close()
    return role and role[0] == required_role

def has_permission(permission_name):
    """Checks if the authenticated user has a specific permission."""
    if not is_authenticated():
        return False

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            SELECT p.PermissionName
            FROM Permissions p
            JOIN RolePermissions rp ON p.PermissionID = rp.PermissionID
            JOIN UserRoles ur ON rp.RoleID = ur.RoleID
            WHERE ur.UserID = ? AND p.PermissionName = ?
            """,
            (session['user_id'], permission_name)
        )
        permission = cursor.fetchone()
        return permission is not None
    finally:
        cursor.close()
        conn.close()
        
def check_password(password, hashed):
    from werkzeug.security import check_password_hash
    return check_password_hash(hashed, password)

# Generate Verification Code
def generate_verification_code(length=6):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

# Send Verification Email
def send_verification_email(email, code):
    msg = Message('Verify Your Email', sender='your_email@gmail.com', recipients=[email])
    msg.body = f'Your verification code is: {code}'
    mail.send(msg)
    print(msg)

# REGISTER ROUTE
@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        username = form.username.data
        email = form.email.data
        password_hash = generate_password_hash(form.password.data)  # Hash the password
        verification_code = generate_verification_code()

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            cursor.execute(
                "EXEC RegisterUser ?, ?, ?, ?",
                username,
                email,
                password_hash,
                verification_code
            )
            conn.commit()

            send_verification_email(email, verification_code)

            flash('Registration successful! A verification email has been sent.', 'success')
            return redirect(url_for('verify_email'))

        except pyodbc.IntegrityError:
            flash('Username or email already exists. Please try again.', 'danger')
        except Exception as e:
            flash(f'An error occurred: {str(e)}', 'danger')
        finally:
            cursor.close()
            conn.close()

    return render_template('register.html', form=form)

# LOGIN ROUTE
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')

        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("EXEC CheckUserLogin ?", email)
            user = cursor.fetchone()

            if user:
                user_id, username, password_hash, is_verified = user

                if not is_verified:
                    flash('Your email is not verified. Please verify it to log in.', 'warning')
                    return redirect(url_for('verify_email'))

                if check_password_hash(password_hash, password):
                    session['user_id'] = user_id
                    session['username'] = username
                    flash('Login successful!', 'success')
                    return redirect(url_for('index'))
                else:
                    flash('Invalid password. Please try again.', 'danger')
            else:
                flash('Invalid email or user does not exist.', 'danger')

        except Exception as e:
            flash(f"Error during login: {e}", 'danger')
        finally:
            cursor.close()
            conn.close()

    return render_template('login.html')

#VERIFY ROUTE
@app.route('/verify', methods=['GET', 'POST'])
def verify_email():
    if request.method == 'POST':
        email = request.form.get('email')
        code = request.form.get('code')

        print(f"Form Data: Email={email}, Code={code}")  # Логирование для отладки

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            # Вызов хранимой процедуры
            cursor.execute("EXEC VerifyUserEmail ?, ?", (email, code))
            result = cursor.fetchone()
            print(f"Result from procedure: {result}")  # Логирование результата

            # Обработка результата
            if result and result[0] == 'SUCCESS':
                flash('Your email has been verified successfully!', 'success')
                print("Verification successful, redirecting to login...")
                return redirect(url_for('login'))
            elif result and result[0] == 'INVALID_CODE':
                flash('Invalid verification code.', 'danger')
            elif result and result[0] == 'NOT_FOUND':
                flash('User not found.', 'danger')

        except Exception as e:
            print(f"Error: {e}")
            flash(f'An error occurred: {str(e)}', 'danger')

        finally:
            cursor.close()
            conn.close()

    return render_template('verify.html')

# MAIN ROUTES
@app.route('/')
def index():
    if is_authenticated():
        flash('Welcome back!', 'info')
    return render_template('index.html')

from flask import Flask, render_template

app = Flask(__name__)

@app.route('/products')
def products():
    # Фейковые данные вместо БД
    fake_categories = [
        {"CategoryID": 1, "Name": "Keyboards"},
        {"CategoryID": 2, "Name": "Mice"},
        {"CategoryID": 3, "Name": "Headsets"},
    ]

    fake_brands = [
        {"BrandID": 1, "Name": "Razer"},
        {"BrandID": 2, "Name": "Logitech"},
        {"BrandID": 3, "Name": "Corsair"},
    ]

    fake_tags = [
        {"TagID": 1, "Name": "RGB"},
        {"TagID": 2, "Name": "Wireless"},
        {"TagID": 3, "Name": "Gaming"},
    ]

    fake_products = [
        {
            "ProductID": 1,
            "Name": "Cyberpunk Keyboard",
            "BasePrice": 129.99,
            "Description": "A neon-lit mechanical keyboard with a cyberpunk aesthetic.",
            "ImagePath": "images/keyboard.jpg",
            "CategoryName": "Keyboards",
            "BrandName": "Razer",
            "Tags": "RGB, Mechanical"
        },
        {
            "ProductID": 2,
            "Name": "Neon Gaming Mouse",
            "BasePrice": 89.99,
            "Description": "A high-speed gaming mouse with customizable neon lighting.",
            "ImagePath": "images/mouse.jpg",
            "CategoryName": "Mice",
            "BrandName": "Logitech",
            "Tags": "Wireless, RGB"
        },
        {
            "ProductID": 3,
            "Name": "RGB Headset",
            "BasePrice": 149.99,
            "Description": "A premium headset with immersive sound and RGB effects.",
            "ImagePath": "images/headset.jpg",
            "CategoryName": "Headsets",
            "BrandName": "Corsair",
            "Tags": "Wireless, Surround Sound"
        },
    ]

    # Заглушки для пагинации
    total_pages = 1
    current_page = 1
    query_string = ""

    return render_template(
        'products.html',
        categories=fake_categories,
        brands=fake_brands,
        tags=fake_tags,
        products=fake_products,
        total_pages=total_pages,
        current_page=current_page,
        query_string=query_string
    )

 
@app.route('/search', methods=['GET'])
def search():
    conn = get_db_connection()
    cursor = conn.cursor()

    query = request.args.get('q', '').strip()
    per_page = 5
    page = request.args.get('page', 1, type=int)

    try:
        if query:
            cursor.execute(
                "EXEC SearchProducts @Query=?, @Page=?, @PerPage=?", 
                (query, page, per_page)
            )
            products = cursor.fetchall()

            cursor.execute("EXEC GetTotalSearchProducts @Query=?", (query,))
            total_products = cursor.fetchone()[0]
        else:
            products = []
            total_products = 0

        total_pages = (total_products + per_page - 1) // per_page
    except Exception as e:
        flash(f"Error while searching for products: {str(e)}", "danger")
        products = []
        total_pages = 1
    finally:
        cursor.close()
        conn.close()

    query_string = request.query_string.decode('utf-8').replace(f"page={page}", '').strip('&')

    return render_template(
        'search_result.html',
        products=products,
        query=query,
        current_page=page,
        total_pages=total_pages,
        query_string=query_string
    )

from datetime import datetime

@app.route('/product/<int:product_id>')
def product_details(product_id):
    fake_product = {
        "ProductID": product_id,
        "Name": "Cyberpunk Keyboard",
        "Description": "A neon-lit mechanical keyboard with a cyberpunk aesthetic.",
        "BasePrice": 129.99,
        "ImagePath": "images/keyboard.jpg",
        "CategoryName": "Keyboards",
        "BrandName": "Razer",
        "Tags": "RGB, Mechanical",
        "Stock": 15,
        "Reserved": 2,
    }

    fake_reviews = [
        {
            "ReviewID": 1,
            "Comment": "Amazing keyboard! Love the RGB effects.",
            "Rating": 5,
            "CreatedAt": datetime.strptime("2024-03-01", "%Y-%m-%d"),
            "Username": "NeoGamer"
        },
        {
            "ReviewID": 2,
            "Comment": "Keys feel great, but a bit expensive.",
            "Rating": 4,
            "CreatedAt": datetime.strptime("2024-03-02", "%Y-%m-%d"),
            "Username": "TechWizard"
        }
    ]

    return render_template(
        'product_details.html',
        product=fake_product,
        reviews=fake_reviews
    )


@app.route('/product/<int:product_id>/add_review', methods=['POST'])
def add_review(product_id):
    if not session.get('user_id'):
        flash("You must be logged in to leave a review.", "danger")
        return redirect(url_for('product_details', product_id=product_id))

    rating = request.form.get('rating', type=int)
    comment = request.form.get('comment')
    user_id = session['user_id']

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC AddReview @UserID=?, @ProductID=?, @Rating=?, @Comment=?", 
               (user_id, product_id, rating, comment))
        conn.commit()
        flash("Your review has been added.", "success")
    except Exception as e:
        flash(f"Error while adding review: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('product_details', product_id=product_id))
    
@app.route('/logout')
def logout():
    session.pop('user_id', None)
    flash('You have been logged out.', 'info')
    return redirect(url_for('index'))

# FAVORITES
def add_to_favorites_session(product_id):
    favorites = session.get('favorites', [])
    if product_id not in favorites:
        favorites.append(product_id)
        session['favorites'] = favorites

def get_favorites_session():
    return session.get('favorites', [])

@app.route('/favorites')
def favorites():
    if 'user_id' in session:
        user_id = session['user_id']
        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT p.ProductID, p.Name, p.BasePrice, p.ImagePath
                FROM Favorites f
                JOIN Products p ON f.ProductID = p.ProductID
                WHERE f.UserID = ? AND f.IsActive = 1
            """, (user_id,))
            products = cursor.fetchall()
        except Exception as e:
            flash(f"Error fetching favorites: {str(e)}", "danger")
            products = []
        finally:
            cursor.close()
            conn.close()
    else:  
        favorites = session.get('favorites', [])
        if favorites:
            conn = get_db_connection()
            cursor = conn.cursor()

            try:
                placeholders = ','.join(['?'] * len(favorites))
                query = f"SELECT ProductID, Name, BasePrice, ImagePath FROM Products WHERE ProductID IN ({placeholders})"
                cursor.execute(query, favorites)
                products = cursor.fetchall()
            except Exception as e:
                flash(f"Error fetching session favorites: {str(e)}", "danger")
                products = []
            finally:
                cursor.close()
                conn.close()
        else:
            products = []

    return render_template('favorites.html', products=products)

@app.route('/favorites/add/<int:product_id>', methods=['POST'])
def add_to_favorites(product_id):
    if not session.get('user_id'):
        favorites = session.get('favorites', [])
        if product_id in favorites:
            return jsonify({'success': True, 'message': 'Product already in favorites (session)'})
        else:
            favorites.append(product_id)
            session['favorites'] = favorites
            return jsonify({'success': True, 'message': 'Product added to favorites (session)'})

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        user_id = session['user_id']

        cursor.execute("SELECT COUNT(*) FROM Favorites WHERE UserID=? AND ProductID=?", (user_id, product_id))
        already_favorite = cursor.fetchone()[0]

        if already_favorite > 0:
            return jsonify({'success': True, 'message': 'Product already in favorites'})
        else:
            cursor.execute(
                "INSERT INTO Favorites (UserID, ProductID, CreatedAt) VALUES (?, ?, GETDATE())",
                (user_id, product_id)
            )
            conn.commit()
            return jsonify({'success': True, 'message': 'Product added to favorites'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {str(e)}'})
    finally:
        cursor.close()
        conn.close()

@app.route('/favorites/remove/<int:product_id>', methods=['POST'])
def remove_favorite(product_id):
    if 'user_id' in session:
        user_id = session['user_id']
        conn = get_db_connection()
        cursor = conn.cursor()

        try:
            cursor.execute("DELETE FROM Favorites WHERE UserID = ? AND ProductID = ?", (user_id, product_id))
            conn.commit()
            flash("Product removed from favorites.", "success")
        except Exception as e:
            flash(f"Error removing product from favorites: {str(e)}", "danger")
        finally:
            cursor.close()
            conn.close()
    else:
        favorites = session.get('favorites', [])
        if product_id in favorites:
            favorites.remove(product_id)
            session['favorites'] = favorites
            flash("Product removed from session favorites.", "success")
        else:
            flash("Product not found in favorites.", "danger")

    return redirect(url_for('favorites'))

# CART
@app.route('/cart')
def cart():
    if not session.get('user_id'):
        flash("You must be logged in to view your cart.", "danger")
        return redirect(url_for('login'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        user_id = session['user_id']
        cursor.execute("EXEC GetUserCart @UserID=?", (user_id,))
        cart_items = cursor.fetchall()

        total_amount = sum(item.Quantity * item.BasePrice for item in cart_items)
    except Exception as e:
        flash(f"Error while fetching cart: {str(e)}", "danger")
        cart_items = []
        total_amount = 0.0
    finally:
        cursor.close()
        conn.close()

    return render_template('cart.html', cart_items=cart_items, total_amount=total_amount)

@app.route('/cart/add/<int:product_id>', methods=['POST'])
def add_to_cart(product_id):
    if not session.get('user_id'):
        return jsonify({'success': False, 'message': 'You must log in to add to cart'})

    quantity = int(request.form.get('quantity', 1))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC CheckInventory @ProductID=?, @Quantity=?", (product_id, quantity))
        is_available = cursor.fetchone()[0]

        if not is_available:
            return jsonify({'success': False, 'message': 'Not enough stock available'})

        cursor.execute(
            "IF EXISTS (SELECT 1 FROM Cart WHERE UserID=? AND ProductID=?) "
            "UPDATE Cart SET Quantity = Quantity + ? WHERE UserID=? AND ProductID=? "
            "ELSE INSERT INTO Cart (UserID, ProductID, Quantity) VALUES (?, ?, ?)",
            (session['user_id'], product_id, quantity, session['user_id'], product_id, session['user_id'], product_id, quantity)
        )
        conn.commit()
        return jsonify({'success': True, 'message': 'Product added to cart'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'Error: {str(e)}'})
    finally:
        cursor.close()
        conn.close()
        
@app.route('/cart/remove/<int:product_id>', methods=['POST'])
def remove_from_cart(product_id):
    if not session.get('user_id'):
        flash("You must be logged in to remove items from the cart.", "danger")
        return redirect(url_for('login'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        user_id = session['user_id']
        cursor.execute("DELETE FROM Cart WHERE UserID = ? AND ProductID = ?", (user_id, product_id))
        conn.commit()
        flash("Item removed from cart.", "success")
    except Exception as e:
        flash(f"Error while removing item from cart: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('cart'))

# PAYMENT
@app.route('/checkout', methods=['GET', 'POST'])
def checkout():
    if not session.get('user_id'):
        flash('You must be logged in to checkout.', 'danger')
        return redirect(url_for('login'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            payment_card_id = request.form.get('payment_card')
            print("Selected Payment Card ID:", payment_card_id)

            # Проверяем карту
            cursor.execute(
                "SELECT CardID FROM PaymentCards WHERE CardID = ? AND UserID = ? AND IsActive = 1",
                (payment_card_id, session['user_id'])
            )
            card = cursor.fetchone()

            if not card:
                flash('Invalid or inactive payment card.', 'danger')
                return redirect(url_for('checkout'))

            # Создаём заказ
            cursor.execute(
                "EXEC CreateOrder @UserID=?, @PaymentCard=?",
                (session['user_id'], payment_card_id)
            )
            conn.commit()
            print("Order created successfully.")

            # Перенаправляем на страницу подтверждения заказа
            flash('Order placed successfully!', 'success')
            return redirect(url_for('order_confirmation'))  # Перенаправляем после успешного заказа

        # Загружаем данные корзины и платёжных карт
        cursor.execute("EXEC GetUserCart @UserID=?", (session['user_id'],))
        cart_items = cursor.fetchall()
        print("Cart Items Debug:", cart_items)

        total_amount = sum(item[1] * item[5] for item in cart_items) if cart_items else 0.0
        print("Total Amount Debug:", total_amount)

        cursor.execute("EXEC GetPaymentCards @UserID=?", (session['user_id'],))
        payment_cards = cursor.fetchall()
        print("Payment Cards Debug:", payment_cards)

    except Exception as e:
        flash(f"Error during checkout: {str(e)}", 'danger')
        cart_items, payment_cards, total_amount = [], [], 0.0
    finally:
        cursor.close()
        conn.close()

    return render_template(
        'checkout.html',
        cart_items=cart_items,
        payment_cards=payment_cards,
        total_amount=total_amount
    )


# ROUTE: Orders
@app.route('/orders')
def orders():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        user_id = session.get('user_id')
        if not user_id:
            flash('You must be logged in to view your orders.', 'danger')
            return redirect(url_for('login'))

        cursor.execute("SELECT * FROM Orders WHERE UserID = ?", (user_id,))
        orders = cursor.fetchall()
    except Exception as e:
        flash(f"Error fetching orders: {str(e)}", 'danger')
        orders = []
    finally:
        cursor.close()
        conn.close()

    return render_template('orders.html', orders=orders)

@app.route('/order-confirmation')
def order_confirmation():
    return render_template('order_confirmation.html')

# ADMIN PANEL
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

@admin_bp.route('/')
def dashboard():
    return render_template('dashboard.html')

@admin_bp.before_request
def check_admin_access():
    if not has_permission('ManageUsers'):
        flash('Access denied. Administrator only.', 'danger')
        return redirect(url_for('index'))

@admin_bp.route('/users')
def manage_users():
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('index'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC GetAllUsers")
        users = cursor.fetchall()
        if not users:
            flash("No users found in the system.", "info")
    except Exception as e:
        flash(f"Error while fetching users: {e}", "danger")
        users = []
    finally:
        conn.close()

    return render_template('users.html', users=users)

@admin_bp.route('/users/edit/<int:user_id>', methods=['GET', 'POST'])
def edit_user(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        is_active = request.form.get('is_active') == 'on'

        try:
            cursor.execute("""
                EXEC UpdateUser ?, ?, ?, ?
            """, (user_id, username, email, is_active))
            conn.commit()
            flash('User updated successfully!', 'success')
        except Exception as e:
            flash(f'Error updating user: {e}', 'danger')
        finally:
            cursor.close()
            conn.close()
        return redirect(url_for('admin.manage_users'))

    cursor.execute("SELECT UserID, Username, Email, IsActive FROM Users WHERE UserID = ?", (user_id,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    return render_template('edit_user.html', user=user)

@admin_bp.route('/users/delete/<int:user_id>', methods=['POST'])
def delete_user(user_id):
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('admin.manage_users'))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        print(f"Attempting to delete user with ID: {user_id}")
        cursor.execute("EXEC DeleteUser ?", user_id)
        conn.commit()
        print("User deletion executed successfully")
        flash(f'User with ID {user_id} deleted successfully.', 'success')
    except Exception as e:
        print(f"Error while deleting user: {str(e)}")
        flash(f'Error occurred while deleting user: {str(e)}', 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_users'))

@admin_bp.route('/products')
def manage_products():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC GetAllProducts")
        products = cursor.fetchall()
    except Exception as e:
        flash(f"Error while fetching products: {str(e)}", "danger")
        products = []
    finally:
        cursor.close()
        conn.close()

    return render_template('product_manage.html', products=products)

UPLOAD_FOLDER = 'static/uploads/products'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@admin_bp.route('/products/add', methods=['GET', 'POST'])
def add_product():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            name = request.form.get('name')
            description = request.form.get('description')
            base_price = float(request.form.get('base_price'))
            is_active = request.form.get('is_active') == 'on'
            category_id = int(request.form.get('category_id'))
            brand_id = request.form.get('brand_id')
            tag_ids = ','.join(request.form.getlist('tags'))
            stock = request.form.get('stock')

            file = request.files['image']
            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(filepath)
                image_path = filepath.replace('\\', '/').replace('static/', '')
            else:
                flash('Invalid file type. Please upload an image.', 'danger')
                return redirect(request.url)

            cursor.execute(
                "EXEC AddProduct ?, ?, ?, ?, ?, ?, ?, ?, ?",
                (name, description, base_price, is_active, category_id, brand_id, tag_ids, image_path, stock)
            )
            conn.commit()
            flash('Product added successfully!', 'success')
            return redirect(url_for('admin.manage_products'))

        cursor.execute("EXEC GetCategories")
        categories = cursor.fetchall()
        cursor.execute("EXEC GetBrands")
        brands = cursor.fetchall()
        cursor.execute("EXEC GetTags")
        tags = cursor.fetchall()
    except Exception as e:
        flash(f"Error while adding product: {str(e)}", 'danger')
        categories, brands, tags = [], [], []
    finally:
        cursor.close()
        conn.close()

    return render_template('add_product.html', categories=categories, brands=brands, tags=tags)

def split(value, separator=','):
    if value is None:
        return []
    return value.split(separator)

app.jinja_env.filters['split'] = split

@admin_bp.route('/products/edit/<int:product_id>', methods=['GET', 'POST'])
def edit_product(product_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("EXEC GetProductDetails @ProductID = ?", (product_id,))
        product = cursor.fetchone()

        if not product:
            flash('Product not found.', 'danger')
            return redirect(url_for('admin.manage_products'))

        if request.method == 'POST':
            name = request.form.get('name')
            description = request.form.get('description')
            base_price = request.form.get('base_price')
            is_active = request.form.get('is_active') == 'on'
            category_id = request.form.get('category_id')
            brand_id = request.form.get('brand_id') or None  # Установка None, если поле пустое
            tag_ids = ','.join(request.form.getlist('tags'))

            print(f"Name: {name}")
            print(f"Description: {description}")
            print(f"Base Price: {base_price}")
            print(f"Is Active: {is_active}")
            print(f"Category ID: {category_id}")
            print(f"Brand ID: {brand_id}")
            print(f"Tag IDs: {tag_ids}")

            try:
                cursor.execute(
                    "EXEC UpdateProductWithDetails @ProductID = ?, @Name = ?, @Description = ?, @BasePrice = ?, @IsActive = ?, @CategoryID = ?, @BrandID = ?, @TagIDs = ?",
                    (product_id, name, description, base_price, is_active, category_id, brand_id, tag_ids)
                )
                conn.commit()
                flash('Product updated successfully!', 'success')
                return redirect(url_for('admin.manage_products'))
            except Exception as e:
                flash(f"Error executing update procedure: {str(e)}", 'danger')

        cursor.execute("EXEC GetCategories")
        categories = cursor.fetchall()

        cursor.execute("EXEC GetBrands")
        brands = cursor.fetchall()

        cursor.execute("EXEC GetTags")
        tags = cursor.fetchall()

    except Exception as e:
        flash(f"Error while updating product: {str(e)}", "danger")
        product, categories, brands, tags = None, [], [], []
    finally:
        cursor.close()
        conn.close()

    return render_template(
        'edit_product.html',
        product=product,
        categories=categories,
        brands=brands,
        tags=tags
    )


@admin_bp.route('/products/delete/<int:product_id>', methods=['POST'])
def delete_product(product_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC DeleteProductWithDetails ?", (product_id,))
        conn.commit()
        flash('Product deleted successfully!', 'success')
    except Exception as e:
        flash(f"Error while deleting product: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_products'))

@admin_bp.route('/categories', methods=['GET', 'POST'])
def manage_categories():
    conn = get_db_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        is_active = request.form.get('is_active') == 'on'

        try:
            cursor.execute("EXEC AddCategory ?, ?, ?", (name, description, is_active))
            conn.commit()
            flash('Category added successfully!', 'success')
        except Exception as e:
            flash(f"Error while adding category: {str(e)}", 'danger')

    try:
        cursor.execute("EXEC GetCategories")
        categories = cursor.fetchall()
    except Exception as e:
        flash(f"Error while fetching categories: {str(e)}", 'danger')
        categories = []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_categories.html', categories=categories)

@admin_bp.route('/categories/edit/<int:category_id>', methods=['POST'])
def edit_category(category_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        name = request.form.get('name')
        description = request.form.get('description')
        is_active = request.form.get('is_active') == 'on'

        cursor.execute("EXEC UpdateCategory ?, ?, ?, ?", (category_id, name, description, is_active))
        conn.commit()

        flash('Category updated successfully!', 'success')
    except Exception as e:
        flash(f"Error while updating category: {str(e)}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_categories'))

@admin_bp.route('/categories/delete/<int:category_id>', methods=['POST'])
def delete_category(category_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC DeleteCategory ?", (category_id,))
        conn.commit()
        flash('Category deleted successfully!', 'success')
    except Exception as e:
        flash(f"Error while deleting category: {str(e)}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_categories'))

@admin_bp.route('/tags', methods=['GET', 'POST'])
def manage_tags():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            name = request.form.get('name')
            description = request.form.get('description')
            is_active = request.form.get('is_active') == 'on'

            cursor.execute("EXEC AddTag ?, ?, ?", (name, description, is_active))
            conn.commit()
            flash('Tag added successfully!', 'success')

        cursor.execute("EXEC GetTags")
        tags = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing tags: {str(e)}", 'danger')
        tags = []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_tags.html', tags=tags)

@admin_bp.route('/tags/edit/<int:tag_id>', methods=['POST'])
def edit_tag(tag_id):
    name = request.form.get('name')
    description = request.form.get('description')
    is_active = request.form.get('is_active') == 'on'

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "EXEC UpdateTag @TagID = ?, @Name = ?, @Description = ?, @IsActive = ?",
            (tag_id, name, description, is_active)
        )
        conn.commit()
        flash('Tag updated successfully!', 'success')
    except Exception as e:
        flash(f"Error while updating tag: {str(e)}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_tags'))

@admin_bp.route('/tags/delete/<int:tag_id>', methods=['POST'])
def delete_tag(tag_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC DeleteTag @TagID = ?", (tag_id,))
        conn.commit()
        flash('Tag deleted successfully!', 'success')
    except Exception as e:
        flash(f"Error while deleting tag: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_tags'))

@admin_bp.route('/brands', methods=['GET', 'POST'])
def manage_brands():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            name = request.form.get('name')
            description = request.form.get('description')
            is_active = request.form.get('is_active') == 'on'

            cursor.execute("EXEC AddBrand ?, ?, ?", (name, description, is_active))
            conn.commit()
            flash('Brand added successfully!', 'success')

        cursor.execute("EXEC GetBrands")
        brands = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing brands: {str(e)}", 'danger')
        brands = []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_brands.html', brands=brands)

@admin_bp.route('/brands/edit/<int:brand_id>', methods=['POST'])
def edit_brand(brand_id):
    name = request.form.get('name')
    description = request.form.get('description')
    is_active = request.form.get('is_active') == 'on'

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "EXEC UpdateBrand @BrandID = ?, @Name = ?, @Description = ?, @IsActive = ?",
            (brand_id, name, description, is_active)
        )
        conn.commit()
        flash('Brand updated successfully!', 'success')
    except Exception as e:
        flash(f"Error while updating brand: {str(e)}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_brands'))

@admin_bp.route('/brands/delete/<int:brand_id>', methods=['POST'])
def delete_brand(brand_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC DeleteBrand ?", (brand_id,))
        conn.commit()
        flash('Brand deleted successfully!', 'success')
    except Exception as e:
        flash(f"Error while deleting brand: {str(e)}", 'danger')
    finally:
        cursor.close()
        conn.close()

    return redirect(url_for('admin.manage_brands'))

@admin_bp.route('/logs', methods=['GET'])
def view_logs():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC GetLogs")
        logs = cursor.fetchall()
    except Exception as e:
        flash(f"Error while fetching logs: {str(e)}", "danger")
        logs = []
    finally:
        cursor.close()
        conn.close()

    return render_template('view_logs.html', logs=logs)

@admin_bp.route('/roles', methods=['GET', 'POST'])
def manage_roles():
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('admin.dashboard'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            role_name = request.form.get('role_name')
            description = request.form.get('description')
            is_active = request.form.get('is_active') == 'on'

            cursor.execute("INSERT INTO Roles (RoleName, Description, IsActive) VALUES (?, ?, ?)",
                           (role_name, description, is_active))
            conn.commit()
            flash('Role added successfully!', 'success')

        cursor.execute("SELECT RoleID, RoleName, Description, IsActive FROM Roles WHERE IsActive = 1")
        roles = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing roles: {str(e)}", 'danger')
        roles = []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_roles.html', roles=roles)

@admin_bp.route('/permissions', methods=['GET', 'POST'])
def manage_permissions():
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('admin.dashboard'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            permission_name = request.form.get('permission_name')
            description = request.form.get('description')
            is_active = request.form.get('is_active') == 'on'

            cursor.execute("INSERT INTO Permissions (PermissionName, Description, IsActive) VALUES (?, ?, ?)",
                           (permission_name, description, is_active))
            conn.commit()
            flash('Permission added successfully!', 'success')

        cursor.execute("SELECT PermissionID, PermissionName, Description, IsActive FROM Permissions WHERE IsActive = 1")
        permissions = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing permissions: {str(e)}", 'danger')
        permissions = []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_permissions.html', permissions=permissions)

@admin_bp.route('/role_permissions', methods=['GET', 'POST'])
def manage_role_permissions():
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('admin.dashboard'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            role_id = request.form.get('role_id')
            permission_id = request.form.get('permission_id')

            cursor.execute("INSERT INTO RolePermissions (RoleID, PermissionID) VALUES (?, ?)", (role_id, permission_id))
            conn.commit()
            flash('Permission assigned to role successfully!', 'success')

        cursor.execute("SELECT RoleID, RoleName FROM Roles WHERE IsActive = 1")
        roles = cursor.fetchall()

        cursor.execute("SELECT PermissionID, PermissionName FROM Permissions WHERE IsActive = 1")
        permissions = cursor.fetchall()

        cursor.execute("""
            SELECT rp.RolePermissionID, r.RoleName, p.PermissionName
            FROM RolePermissions rp
            JOIN Roles r ON rp.RoleID = r.RoleID
            JOIN Permissions p ON rp.PermissionID = p.PermissionID
        """)
        role_permissions = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing role permissions: {str(e)}", 'danger')
        roles, permissions, role_permissions = [], [], []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_role_permissions.html', roles=roles, permissions=permissions, role_permissions=role_permissions)

@admin_bp.route('/user_roles', methods=['GET', 'POST'])
def manage_user_roles():
    if not has_permission('ManageUsers'):
        flash('Access denied. You do not have the required permission.', 'danger')
        return redirect(url_for('admin.dashboard'))

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        if request.method == 'POST':
            user_id = request.form.get('user_id')
            role_id = request.form.get('role_id')

            cursor.execute("INSERT INTO UserRoles (UserID, RoleID) VALUES (?, ?)", (user_id, role_id))
            conn.commit()
            flash('Role assigned to user successfully!', 'success')

        cursor.execute("SELECT UserID, Username FROM Users WHERE IsActive = 1")
        users = cursor.fetchall()

        cursor.execute("SELECT RoleID, RoleName FROM Roles WHERE IsActive = 1")
        roles = cursor.fetchall()

        cursor.execute("""
            SELECT ur.UserRoleID, u.Username, r.RoleName
            FROM UserRoles ur
            JOIN Users u ON ur.UserID = u.UserID
            JOIN Roles r ON ur.RoleID = r.RoleID
        """)
        user_roles = cursor.fetchall()
    except Exception as e:
        flash(f"Error while managing user roles: {str(e)}", 'danger')
        users, roles, user_roles = [], [], []
    finally:
        cursor.close()
        conn.close()

    return render_template('manage_user_roles.html', users=users, roles=roles, user_roles=user_roles)

def get_inactive_users():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC GetInactiveUsers")
        inactive_users = cursor.fetchall()
        return inactive_users
    except Exception as e:
        print(f"ERROR IN EXTRACTING INACTIVE USERS: {str(e)}")
        return []
    finally:
        cursor.close()
        conn.close()

from apscheduler.schedulers.background import BackgroundScheduler

def notify_inactive_users():
    inactive_users = get_inactive_users()
    if inactive_users:
        print(f"FOUND {len(inactive_users)} INACTIVE USERS:")
        for user in inactive_users:
            print(f"UserID: {user[0]}, Email: {user[1]}, Username: {user[2]}")
    else:
        print("NO INACTIVE USERS")

scheduler = BackgroundScheduler()
scheduler.add_job(func=notify_inactive_users, trigger="interval", minutes=5)
scheduler.start()

import atexit

atexit.register(lambda: scheduler.shutdown())

# REGISTER BLUEPRINT
app.register_blueprint(admin_bp)

if __name__ == '__main__':
    app.run(debug=True)