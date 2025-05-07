let map = L.map('map').setView([40.4093, 49.8671], 12);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: 'Map data © OpenStreetMap contributors'
}).addTo(map);

let points = [];
let chartInstance = null;

map.on('click', function(e) {
    if (points.length >= 2) {
        points.forEach(p => map.removeLayer(p.marker));
        points = [];
        document.getElementById('calculateBtn').disabled = true;
    }

    let marker = L.marker(e.latlng).addTo(map);
    points.push({ lat: e.latlng.lat, lng: e.latlng.lng, marker: marker });

    if (points.length === 2) {
        document.getElementById('calculateBtn').disabled = false;
    }
});

let selectedAlgorithm = document.getElementById('algorithmSelect').value;
document.getElementById('algorithmSelect').addEventListener('change', (e) => {
    selectedAlgorithm = e.target.value;
});

function showResults(data, label) {
    let container = document.getElementById('results');
    const placeholder = document.getElementById('placeholder');
    if (placeholder) placeholder.remove();

    if (label === "all") {
        let out = '<h3>All Algorithm Comparison</h3><div class="result-box">';
        for (let algo in data) {
            out += `<p><strong>${algo}</strong>: ${data[algo].distance_km} km, ${data[algo].congestion}% congestion, ${data[algo].travel_time_min} min</p>`;
        }
        out += '</div>';
        container.innerHTML = out;
    } else if (data && data.distance_km !== undefined) {
        container.innerHTML = `
            <h3>Results (${label})</h3>
            <div class="result-box">
                <p><strong>Distance:</strong> ${data.distance_km} km</p>
                <p><strong>Congestion:</strong> ${data.congestion}%</p>
                <p><strong>Travel Time:</strong> ${data.travel_time_min} minutes</p>
            </div>`;
    } else {
        container.innerHTML = `<p class="error">No result data available for ${label}.</p>`;
    }
}

function renderSingleChart(data, label) {
    const ctx = document.getElementById('chart').getContext('2d');
    if (chartInstance) chartInstance.destroy();

    chartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Distance (km)', 'Congestion (%)', 'Travel Time (min)'],
            datasets: [{
                label: label,
                data: [data.distance_km, data.congestion, data.travel_time_min],
                backgroundColor: [
                    'rgba(255, 99, 132, 0.5)',
                    'rgba(255, 206, 86, 0.5)',
                    'rgba(75, 192, 192, 0.5)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)',
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true
                }
            }
        }
    });
}

function renderCompareChart(allData) {
    const ctx = document.getElementById('chart').getContext('2d');
    const COLORS = [
        { bg: 'rgba(255, 99, 132, 0.2)', border: 'rgba(255, 99, 132, 1)' },   // Red
        { bg: 'rgba(54, 162, 235, 0.2)', border: 'rgba(54, 162, 235, 1)' },   // Blue
        { bg: 'rgba(255, 206, 86, 0.2)', border: 'rgba(255, 206, 86, 1)' },   // Yellow
        { bg: 'rgba(75, 192, 192, 0.2)', border: 'rgba(75, 192, 192, 1)' }    // Teal
    ];
    
    if (chartInstance) chartInstance.destroy();

    const datasets = Object.keys(allData).map((algo, index) => {
        const color = COLORS[index % COLORS.length];
        return {
            label: algo,
            data: [
                allData[algo].distance_km,
                allData[algo].congestion,
                allData[algo].travel_time_min
            ],
            fill: true,
            backgroundColor: color.bg,
            borderColor: color.border,
            borderWidth: 2
        };
    });
    
    chartInstance = new Chart(ctx, {
        type: 'radar',
        data: {
            labels: ['Distance (km)', 'Congestion (%)', 'Travel Time (min)'],
            datasets: datasets
        },
        options: {
            responsive: true,
            scales: {
                r: {
                    beginAtZero: true
                }
            }
        }
    });
}

document.getElementById('calculateBtn').addEventListener('click', () => {
    if (points.length < 2) return;

    document.getElementById('loading').style.display = 'block';

    fetch("/calculate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            start: { lat: points[0].lat, lng: points[0].lng },
            end: { lat: points[1].lat, lng: points[1].lng },
            algorithm: selectedAlgorithm
        })
    })
    .then(res => res.json())
    .then(data => {
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            showResults(data, selectedAlgorithm);
            renderSingleChart(data, selectedAlgorithm);
        }, 1000);
    });
});

document.getElementById('compareAllBtn').addEventListener('click', () => {
    if (points.length < 2) return;

    document.getElementById('loading').style.display = 'block';

    fetch("/calculate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            start: { lat: points[0].lat, lng: points[0].lng },
            end: { lat: points[1].lat, lng: points[1].lng },
            algorithm: "all"
        })
    })
    .then(res => res.json())
    .then(data => {
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            showResults(data, "all");
            renderCompareChart(data);
        }, 1000);
    });
    
});

document.getElementById('hybridBtn').addEventListener('click', () => {
    document.getElementById('loading').style.display = 'block';

    fetch("/calculate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            start: { lat: points[0].lat, lng: points[0].lng },
            end: { lat: points[1].lat, lng: points[1].lng },
            algorithm: "Hybrid"
        })
    })
    .then(res => res.json())
    .then(data => {
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            showResults(data, "Hybrid Scenario");
            renderSingleChart(data);
        }, 1000);
    });
});
