//
//  MovieDetailsViewController.swift
//  Flix
//
//  Created by Jasmyne Roberts on 9/26/20.
//  Copyright © 2020 Jasmyne Roberts. All rights reserved.
//

import UIKit
import AlamofireImage

class MovieDetailsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var backdropView: UIImageView!
    @IBOutlet weak var posterView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var synopsisLabel: UILabel!
    
    var gradient: CAGradientLayer!
    
    // Outlet for poster to segue to movie trailer
    @IBAction func didTapPoster(_ sender: UITapGestureRecognizer) {
    }
    
    // Outlet for related movies row
    @IBOutlet weak var relatedMoviesLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Scrollview to contain everything except poster and title
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Dictionary provides details of individual movie
    var movie: [String:Any]!
    
    // List of dictionaries provides posters of related movies, and segue to related movie details
    var relatedMovies = [[String:Any]]()
    var indexTapped: Int = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = movie["title"] as? String
        titleLabel.sizeToFit()
        
        synopsisLabel.text = movie["overview"] as? String
        synopsisLabel.sizeToFit()
        
        let baseUrl = "https://image.tmdb.org/t/p/w185"
        let posterPath = movie["poster_path"] as! String
        let posterUrl = URL(string: baseUrl + posterPath)!
        
        posterView.af.setImage(withURL: posterUrl)
        
        let backdropPath = movie["backdrop_path"] as! String
        let backdropUrl = URL(string: "https://image.tmdb.org/t/p/w780" + backdropPath)!
        backdropView.af.setImage(withURL: backdropUrl)
        
        // Create gradient for backdrop layer
        gradient = CAGradientLayer()
        gradient.frame = backdropView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0, 0.75, 1]
        backdropView.layer.addSublayer(gradient)
        
        // Related Movies Collection View
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4

        let width = (view.frame.size.width - layout.minimumInteritemSpacing * 3) / 3.5
        layout.itemSize = CGSize(width: width, height: width * 1.5)
        
        let movieId = movie["id"] as! Int
        let preUrl = "https://api.themoviedb.org/3/movie/"
        let postUrl = "/similar?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let fullUrl = preUrl + String(movieId) + postUrl
        let url = URL(string: fullUrl)!
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data, response, error) in
           // This will run when the network request returns
           if let error = error {
              print(error.localizedDescription)
           } else if let data = data {
              let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

              // Get the array of related movies
            self.relatedMovies = dataDictionary["results"] as! [[String : Any]]
            
            if self.relatedMovies.isEmpty {
                self.relatedMoviesLabel.text = ""
            } else {
                self.relatedMoviesLabel.text = "Related Movies"
            }
              
              // Reload your collection view data
            self.collectionView.reloadData()
            
           }

        }
        task.resume()
    
    }
    
    // Keep gradient within bounds even if view is rotated
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            gradient.frame = backdropView.bounds
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return relatedMovies.count
    }
    
    
    // @objc makes function have objective C runtime
    @objc func didTapRelatedPoster(gestureRecognizer: UIGestureRecognizer) {
        let view = gestureRecognizer.view
        guard let newView = view else {return}
        let index = newView.tag
        let movie = relatedMovies[index]
        
        // look at storyboard, look for main storyboard, and instantiate a view controller in main storyboard. identify view controller using unique identifier
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MovieDetailsViewController") as! MovieDetailsViewController
        vc.movie = movie
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RelatedMovieGridCell", for: indexPath) as! RelatedMovieGridCell
        cell.tag = indexPath.item
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapRelatedPoster(gestureRecognizer:)))
        cell.addGestureRecognizer(tapGestureRecognizer)
        let relatedMovie = relatedMovies[indexPath.item]
        
        let relatedBaseUrl = "https://image.tmdb.org/t/p/w185"
        let relatedPosterPath = relatedMovie["poster_path"] as? String ?? movie["poster_path"] as! String // I left this optional casting here because there were instances where the movie object existed, but no poster path
        let relatedPosterUrl = URL(string: relatedBaseUrl + relatedPosterPath)!
        
        cell.relatedPosterView.af.setImage(withURL: relatedPosterUrl)

        return cell
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Find the selected movie id
        let movieId = movie["id"] as! Int
        
        // Pass the selected movie to the trailer view controller
        let trailerViewController = segue.destination as! MovieTrailerViewController
        trailerViewController.movieId = movieId
    }
    

}
