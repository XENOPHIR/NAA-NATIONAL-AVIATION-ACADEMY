# 🧠 AI-Based Optimization of Urban Transport Routes in Azerbaijan 🚍

This project is part of a scientific research thesis titled  
**"AI-Based Optimization of Urban Transport Routes in Azerbaijan"**,  
presented at the **26th Student Scientific and Technical Conference** at the **National Aviation Academy**.

📄 *Link to published thesis (coming soon...)*

---

## 📌 Project Purpose

The aim of this project is to explore how Artificial Intelligence (AI) and Machine Learning (ML) techniques can enhance the efficiency of public transportation routing in urban areas, specifically in **Baku, Azerbaijan**.

It compares multiple routing algorithms and models how they behave under realistic traffic conditions, using a hybrid simulation-based prototype.

### Goals

- Identify limitations of traditional static routing methods  
- Simulate congestion-aware routing through algorithmic modeling  
- Create a **hybrid model** that leverages the strengths of multiple techniques

---

## ⚙️ Algorithms Used

| Algorithm              | Strength                               | Limitation                                |
|-----------------------|-----------------------------------------|--------------------------------------------|
| **Dijkstra**           | Always finds the shortest path          | Ignores traffic, slow with dynamic data    |
| **A\***               | Uses heuristics to guess best routes     | Heuristics may oversimplify traffic impact |
| **Genetic**            | Tries many combinations and evolves     | High compute time, unstable at times       |
| **Reinforcement Learning** | Learns from feedback and adapts   | Needs many iterations to converge          |

> The **Hybrid** logic blends the best of all four approaches:  
> **Dijkstra + A\* + Genetic + Reinforcement Learning**

---

## 🧮 Traffic-Aware Simulation

To simulate traffic realistically, we used **congestion multipliers**:

Example:

```bash
Original Distance: 4 km
Traffic Level: 80%
Multiplier = 1.8
Adjusted = 4 km × 1.8 = 7.2 km
```

This allows even static algorithms like Dijkstra to simulate real-world delays.

---

## 🗺️ Demo Route Simulation

The prototype demonstrates a route from  
**Qara Qarayev** → **National Aviation Academy (MAA)**

Different algorithms are compared using simulated traffic patterns.

---

## 💻 Live Demo (Prototype)

🧪 A web-based demo has been created using **Flask** + **Leaflet.js** + **Chart.js**  
Each algorithm can be selected and tested interactively.  
A "Hybrid" button simulates combined results.

> ⚠️ The demo uses **predefined results** to simulate behavior,  
> as full real-time calculations would require extensive infrastructure.

---

## 📊 Results Summary

- **Dijkstra**: Fastest route, but ignores congestion  
- **A\***: Smarter route selection, still limited by prediction accuracy  
- **Genetic**: Creative exploration, but slow to converge  
- **RL**: Best performance after multiple iterations  
- **Hybrid**: Balanced trade-off between speed, prediction, and adaptability

---

## 🌍 Not a Navigation App

Unlike Google Maps or Waze, this system is not built for daily use.  
It is intended for:

- Academic and research simulations  
- Urban planning and smart city development  
- Transportation system analysis

> 🧭 Google shows you the way.  
> 💡 This system helps **design a better way**.

---

## 🔮 Potential Future Enhancements

- Real-time traffic data (e.g., via GPS or public sensors)  
- Learning from user behavior (adaptive routing)  
- Integration with transport authority dashboards  
- Expansion to **multi-modal transport networks**

---

## 🛠️ Tech Stack

- Python 3.x
- Flask
- Leaflet.js (mapping)
- Chart.js (visualization)
- HTML / CSS / JS
- Jupyter Notebook (data experiments)

---

## 👨‍🎓 Author

**Murad Babayev**  
Computer Engineering Student  
National Aviation Academy, Azerbaijan  
**Supervisor**: Tabriz Osmanli

---
