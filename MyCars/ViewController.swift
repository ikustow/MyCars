//
//  ViewController.swift
//  MyCars
//
//  Created by Ilya Kustov on 05/10/20.
//  Copyright © Ilya Kustov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet{
            updateSegmentedControl()
            
            segmentedControl.selectedSegmentTintColor = .white
            
            let whiteTitleTextAttr = [NSAttributedString.Key.foregroundColor: UIColor.white]
            
            let blackTitleTextAttr = [NSAttributedString.Key.foregroundColor: UIColor.black]
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttr, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttr, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        
        updateSegmentedControl()
        
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch  let error as NSError{
            print(error.localizedDescription)
        }
        
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        
        let allertController = UIAlertController(title: "Rate it", message: "Rate this car please", preferredStyle: .alert)
        
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = allertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        allertController.addTextField{
            textField in
            textField.keyboardType = .numberPad
        }
        
        allertController.addAction(rateAction)
        allertController.addAction(cancelAction)
        
        present(allertController, animated: true, completion: nil)
        
    }
    
    private func updateSegmentedControl(){
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            insertDataFrom(selectedCar: car!)
        } catch let error as NSError{
            print(error.localizedDescription)
        }
        
    }
    
    private func update(rating: Double){
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch  let error as NSError{
            let alertC = UIAlertController (title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default)
            
            alertC.addAction(okAction)
            present(alertC, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFrom(selectedCar car:Car){
        carImageView.image = UIImage(data: car.imageData!)
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoice)
        ratingLabel.text = "Rating: \(car.rating)/10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        
        lastTimeStartedLabel.text = "Last time stared: \(dateFormatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    
    private func getDataFromFile(){
        
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
        }   catch let error as NSError{
            print(error.localizedDescription)
        }
        
        guard records == 0 else {return}
        
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
              let dataArray = NSArray (contentsOfFile: pathToFile) else {return}
        for dict in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            
            let carDict = dict as! [String: AnyObject]
            car.mark = carDict["mark"] as? String
            car.model = carDict["model"] as? String
            car.rating = carDict["rating"] as! Double
            car.lastStarted = carDict["lastStarted"] as? Date
            car.timesDriven = carDict["timesDriven"] as! Int16
            car.myChoice = carDict["myChoice"] as! Bool
            
            let imageName = carDict["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image?.pngData()
            car.imageData = imageData
            
            if let colorDict = carDict["tintColor"] as? [String: Float]{
                car.tintColor = getColor(colorDict: colorDict)
            }
            
            
        }
    }
    
    private func getColor(colorDict: [String: Float]) -> UIColor{
        
        guard let red = colorDict["red"],
              let green = colorDict["green"],
              let blue = colorDict["blue"]
        else {return UIColor()}
        
        return UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getDataFromFile()
        
    }
    
}

