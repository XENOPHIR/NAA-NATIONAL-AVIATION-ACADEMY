const cards = document.querySelectorAll('.testimonial-card');
let currentIndex = 0;

function showNextCard() {
    cards[currentIndex].classList.remove('active');
    currentIndex = (currentIndex + 1) % cards.length;
    cards[currentIndex].classList.add('active');
}

setInterval(showNextCard, 3000);

function toggleReviews() {
    var reviewsSection = document.getElementById("reviews-section");
    if (reviewsSection.style.display === "none" || reviewsSection.style.display === "") {
        reviewsSection.style.display = "block";
    } else {
        reviewsSection.style.display = "none";
    }
}

