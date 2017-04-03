//
//  DetailViewController.swift
//  DoughChallenge
//
//  Created by Jared Wheeler on 4/1/17.
//  Copyright © 2017 Jared Wheeler. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var chartContainer: UIImageView!
    
    func configureView() {
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.symbol
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        self.retrieveQuoteHistoryData()
    }
    
    //Here we hit the Yahoo endpoint for a month of quote data...
    //I'll say that I normally wouldn't couple a remote data call like this
    //directly into a viewController.  I typically prefer to architect stuff
    //like this into the DataModel layer.  Doing it here just to keep things
    //simple and within the scope of this exercise.
    //Also, I typically try to treat endpoint formulation with a little more respect
    //than I do here.  Again, limiting scope for the sake of the exercise.
    func retrieveQuoteHistoryData() {
        guard let detail = self.detailItem else {return}
        guard let symbol = detail.symbol else {return}
        
        //Prep all the calendar data we'll need to construct a date window for the request
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return }
        let yesterdayComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else { return }
        let lastMonthComponents = calendar.dateComponents([.year, .month, .day], from: lastMonth)
        
        //Smoosh up an endpoint string
        let endpointString: String = "http://ichart.finance.yahoo.com/table.csv?s=\(symbol)&a=\(lastMonthComponents.month! - 1)&b=\(lastMonthComponents.day!)&c=\(lastMonthComponents.year!)&d=\(yesterdayComponents.month! - 1)&e=\(yesterdayComponents.day!)&f=\(yesterdayComponents.year!)&g=d&ignore=.csv"
        guard let endpointURL = URL(string: endpointString) else {return}
        
        //Doing the network stuff witha raw URLSesh.  Again, would typically architect this into
        //the DataModel and make sure it behaves within an app-wide concurrency model.
        //(Which would include backgrounded network calls, bouncing in and out of CoreData, etc.)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: endpointURL) { (data, response, error) in
            guard let responseData = data else {return}
            guard let historyCSV = String(data: responseData, encoding:.utf8) else {return}
            if historyCSV.hasPrefix("<!") {return} //Quick n dirty check against a 404 from the service
            let csv = CSwiftV(with: historyCSV)
            var historyData: [[Float]] = []
            for i in 0 ..< csv.rows.count {
                var row = csv.rows[i]
                //Do some culling on the returned CSV data so it fits
                //our rendering flow downstream.
                //Skip anything that comes back empty.
                if row.count > 0 {
                    row.remove(at: 0)
                    row.remove(at: 4)
                    historyData.append(row.map({Float($0)!}))
                }
            }
            //Back up to main for UIView work
            DispatchQueue.main.async {
                self.renderHistoryData(with:historyData)
            }
        }
        dataTask.resume()
    }
    
    //Here we render the quote history data into a Candlestick chart.
    //This is a super-raw implementation, in the spirit of, "you get the idea..."
    //Like the above network activity, it's limited to fit within the scope of the exercise.
    //No legend, no overlays, full-on Ed Tufte.
    func renderHistoryData(with historyData: [[Float]]) {
        let chartSize = CGSize(width:self.view.bounds.size.width, height:self.view.bounds.size.height)
        UIGraphicsBeginImageContext(chartSize)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(gray: 0, alpha: 1)
        let bgRect = CGRect(x:0, y:0, width:chartSize.width, height:chartSize.height)
        context?.addRect(bgRect)
        context?.drawPath(using: .fill)
        
        //Pull a min/max for the entire chart from the history data
        //With a little more time, I'd cook up a map/reduce to get this
        var minY: Float = FLT_MAX
        var maxY:Float = 0
        for item in historyData {
            minY = Swift.min(minY, item.min()!)
            maxY = Swift.max(maxY, item.max()!)
        }
        
        //Here we set up some transform values
        //We need the lowest displayed value to touch the baseline of the chart
        //and the highest displayed value to hit the top
        let yScale = chartSize.height / CGFloat(maxY - minY)
        let yOffset = CGFloat(minY) * -yScale
        
        //Lop on history data and draw the candlesticks
        for i in 0 ..< historyData.count {
            let item = historyData[i]
            
            //Hardcoded based on the header row of the CSV
            let openVal = CGFloat(item[0])
            let highVal = CGFloat(item[1])
            let lowVal = CGFloat(item[2])
            let closeVal = CGFloat(item[3])
            
            //Transform price data into chart space
            let openYVal = chartSize.height - (openVal * yScale + yOffset)
            let highYVal = chartSize.height - (highVal * yScale + yOffset)
            let lowYVal = chartSize.height - (lowVal * yScale + yOffset)
            let closeYVal = chartSize.height - (closeVal * yScale + yOffset)
            
            //Newest data on the right, oldest to the left
            let x = chartSize.width - ((chartSize.width / CGFloat(historyData.count)) * CGFloat(i))
            
            //Draw the high/low line
            var rect: CGRect = CGRect(x:x+3,y:lowYVal,width:1,height:highYVal-lowYVal)
            context?.setFillColor(UIColor.white.cgColor)
            context?.addRect(rect)
            context?.drawPath(using: .fill)
            
            //Draw the open close box
            if openVal < closeVal {
                rect = CGRect(x:x, y:CGFloat(openYVal), width:6, height: CGFloat(closeYVal - openYVal))
                context?.setFillColor(UIColor.green.cgColor)
            } else {
                rect = CGRect(x:x, y:CGFloat(closeYVal), width:6, height: CGFloat(openYVal - closeYVal))
                context?.setFillColor(UIColor.red.cgColor)
            }
            context?.addRect(rect)
            context?.drawPath(using: .fill)
        }
        
        //Extract a UIImage from the context and drop it into the view
        let chartImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.chartContainer.image = chartImage
    }
    
    var detailItem: Listing? {
        didSet {
            self.configureView()
        }
    }
    
    
}
