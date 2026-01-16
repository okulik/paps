#include <iostream>
#include <fstream>
#include <random>
#include <vector>
#include <iomanip>
#include <chrono>

struct Point {
    double latitude;
    double longitude;
};

int main() {
    const int NUM_POINTS = 10000000;
    const std::string OUTPUT_FILE = "points.json";
    
    // Random number generators
    std::random_device rd;
    std::mt19937 gen(rd());
    
    // Latitude: -90 to +90 degrees
    std::uniform_real_distribution<double> lat_dist(-90.0, 90.0);
    
    // Longitude: -180 to +180 degrees  
    std::uniform_real_distribution<double> lng_dist(-180.0, 180.0);
    
    std::cout << "Generating " << NUM_POINTS << " random latitude/longitude points..." << std::endl;
    
    auto start = std::chrono::high_resolution_clock::now();
    
    std::ofstream file(OUTPUT_FILE);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << OUTPUT_FILE << std::endl;
        return 1;
    }
    
    // Start JSON array
    file << "{\"pairs\": [\n";
    
    for (int i = 0; i < NUM_POINTS; ++i) {
        Point pointA;
        pointA.latitude = lat_dist(gen);
        pointA.longitude = lng_dist(gen);

        Point pointB;
        pointB.latitude = lat_dist(gen);
        pointB.longitude = lng_dist(gen);

        file << "  {\"x0\": " << std::fixed << std::setprecision(8) << pointA.latitude
             << ", \"y0\": " << std::setprecision(8) << pointA.longitude
             << ", \"x1\": " << std::setprecision(8) << pointB.latitude
             << ", \"y1\": " << std::setprecision(8) << pointB.longitude << "}";
        
        if (i < NUM_POINTS - 1) {
            file << ",";
        }
        file << "\n";
        
        // Progress indicator
        if ((i + 1) % 1000000 == 0) {
            std::cout << "Generated " << (i + 1) / 1000000 << "M point pairs..." << std::endl;
        }
    }
    
    // End JSON array
    file << "]}\n";
    file.close();
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    std::cout << "Successfully generated " << NUM_POINTS << " points!" << std::endl;
    std::cout << "Output file: " << OUTPUT_FILE << std::endl;
    std::cout << "Time taken: " << duration.count() / 1000.0 << " seconds" << std::endl;
    
    return 0;
}
