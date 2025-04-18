from flask import Flask, request, render_template
import dns.resolver
from cache import get_from_cache, save_to_cache

app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
    ip_address = None
    source = None
    domain = ""

    if request.method == "POST":
        domain = request.form["domain"]
        ip_address = get_from_cache(domain)
        if ip_address:
            source = "cache"
        else:
            try:
                answer = dns.resolver.resolve(domain, "A")
                ip_address = answer[0].to_text()
                save_to_cache(domain, ip_address)
                source = "DNS server"
            except Exception as e:
                ip_address = f"Error: {e}"
                source = "error"

    return render_template("index.html", ip_address=ip_address, source=source, domain=domain)

if __name__ == "__main__":
    app.run(debug=True)
