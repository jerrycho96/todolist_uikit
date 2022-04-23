//
//  ViewController.swift
//  ToDoList
//
//  Created by 조영진 on 2022/04/22.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    // Edit 버튼이 done으로 바뀌면 Edit 버튼은 메모리에서 해제된다.
    // 다시 Edit 버튼을 사용해야하기 때문에 weak이 아닌 strong으로 선언
    @IBOutlet var editButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem?
    
    var tasks = [Task]() {
        // 프로퍼티 옵저버
        // 배열에 항목이 추가될 때마다 실행
        didSet {
            self.saveTasks()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTap))
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.loadTasks()
    }
    
    // objc -> swift에서 정의된 메서드를 object-c에서도 인식할 수 있게.
    @objc func doneButtonTap() {
        self.navigationItem.leftBarButtonItem = self.editButton
        self.tableView.setEditing(false, animated: true)
    }
    
    @IBAction func tabEditButton(_ sender: UIBarButtonItem) {
        // 리스트가 비어있을 경우에는 edit 버튼이 눌려도 필요가 없기에 guard문으로 예외처리.
        guard !self.tasks.isEmpty else {return}
        
        self.navigationItem.leftBarButtonItem = self.doneButton
        self.tableView.setEditing(true, animated: true)
    }
    
    @IBAction func tabAddButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "할 일 등록", message: nil, preferredStyle: .alert)
        let registerButton = UIAlertAction(title: "등록", style: .default) { [weak self] _ in
            guard let title = alert.textFields?[0].text else { return }
            let task = Task(title: title, done: false)
            self?.tasks.append(task)
            self?.tableView.reloadData()
        }
        let cancelButton = UIAlertAction(title: "취소", style: .default, handler: nil)
        alert.addAction(cancelButton)
        alert.addAction(registerButton)
        alert.addTextField { textField in
            textField.placeholder = "할 일을 입력해주세요."
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveTasks() {
        // 리스트를 스토리지에 저장하기 위해 key:value로 맵핑
        let data = self.tasks.map {
            [
                "title": $0.title,
                "done": $0.done
            ]
        }
        // 로컬 스토리지에 저장 -> 앱을 껐다켜도 데이터가 남아있음.
        let userDefaults = UserDefaults.standard
        userDefaults.set(data, forKey: "tasks")
    }
    
    func loadTasks() {
        let userDefaults = UserDefaults.standard
        // 저장된 데이터 가져오기
        // object 메서드는 Any 타입으로 리턴되기 때문에 딕셔너리 배열 타입으로 타입 캐스팅을 해줘야함.
        guard let data = userDefaults.object(forKey: "tasks") as? [[String: Any]] else { return }
        // 데이터 맵핑
        self.tasks = data.compactMap {
            // 딕셔너리의 value가 Any 타입이니 String으로 캐스팅
            // 변환에 실패하면 nil 리턴
            guard let title = $0["title"] as? String else { return nil }
            guard let done = $0["done"] as? Bool else { return nil }
            
            // Task 타입이 되게 인스턴스화
            return Task(title: title, done: done)
        }
        
    }
}

extension ViewController: UITableViewDataSource {
    // 테이블 뷰를 사용하기 위해서 필수로 선언해야하는 함수들.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 배열의 개수를 반환
        return self.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 특정 row를 그리기 위해 cell을 반환해야한다.
        // 스토리보드에 정의한 셀을 가져온다.
        // 셀을 재사용하여 메모리를 낭비하지 않게 해줌.
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let task = self.tasks[indexPath.row]
        cell.textLabel?.text = task.title
        if task.done {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.tasks.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        // 리스트가 비었으면 편집모드를 빠져나옴.
        if self.tasks.isEmpty {
            self.doneButtonTap()
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var tasks = self.tasks
        let task = tasks[sourceIndexPath.row]
        tasks.remove(at: sourceIndexPath.row) // 해당 위치 삭제
        tasks.insert(task, at: destinationIndexPath.row) // 바뀐 위치에 삽입
        self.tasks = tasks // 바뀐 리스트 대입
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var task = self.tasks[indexPath.row]
        task.done = !task.done
        self.tasks[indexPath.row] = task
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
