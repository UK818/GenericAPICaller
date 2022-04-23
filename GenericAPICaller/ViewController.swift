//
//  ViewController.swift
//  GenericAPICaller
//
//  Created by mac on 23/04/2022.
//

import UIKit

struct User: Codable {
	let name: String
	let email: String
}

struct toDoListItem: Codable {
	let title: String
	let completed: Bool
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	struct Constants {
		static let usersUrl = URL(string: "https://jsonplaceholder.typicode.com/users")
		static let todoListUrl = URL(string: "https://jsonplaceholder.typicode.com/todos")
	}
	
	private var models: [Codable] = []
	
	private let table: UITableView = {
		let table = UITableView()
		table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		return table
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(table)
		table.frame = view.bounds
		table.delegate = self
		table.dataSource = self
		
		fetchToDoItems()
	}
	
	func fetchData() {
		URLSession.shared.request(
			url: Constants.usersUrl,
			expecting: [User].self
		) { [weak self] result in
			switch result {
				case .success(let users):
					DispatchQueue.main.async {
						self?.models = users
						self?.table.reloadData()
					}
				case .failure(let error):
					print(error)
			}
			}
	}
	
	func fetchToDoItems() {
		URLSession.shared.request(
			url: Constants.todoListUrl,
			expecting: [toDoListItem].self
		) { [weak self] result in
			switch result {
				case .success(let todos):
					DispatchQueue.main.async {
						self?.models = todos
						self?.table.reloadData()
					}
				case .failure(let error):
					print(error)
			}
			}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		models.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = (models[indexPath.row] as? User)?.name
		cell.textLabel?.text = (models[indexPath.row] as? toDoListItem)?.title
		if let item = models[indexPath.row] as? toDoListItem {
			cell.accessoryType = item.completed ? .checkmark : .none
		}
		return cell
	}

}

extension URLSession {
	
	enum CustomError: Error {
		case invalidUrl
		case invalidData
	}
	
	func request<T: Codable>(
		url: URL?,
		expecting: T.Type,
		completion: @escaping (Result<T, Error>) -> Void
	) {
		guard let url = url else {
			completion(.failure(CustomError.invalidUrl))
			return
		}
		
		let task = dataTask(with: url) { data, _, error in
			guard let data = data else {
				if let error = error {
					completion(.failure(error))
				} else {
					completion(.failure(CustomError.invalidData))
				}
				return
			}
			
			do {
				let result = try JSONDecoder().decode(expecting, from: data)
				completion(.success(result))
			}
			catch {
				completion(.failure(error))
			}
			
		}
		
		task.resume()
	}
}

