import UIKit
import RxSwift

public protocol UIControlType: NSObjectProtocol {
	typealias ControlType: UIControl = Self
}

extension UIControlType {
	private func typedSelf() -> ControlType {
		return self as! ControlType
	}
	
	public func rxs_triggerForControlEvents<T>(controlEvents: UIControlEvents, valueGetter: (Self)->T) -> Trigger<T> {
		let trigger = TargetActionTrigger<T> { [weak self] in
			guard let this = self else { throw RxsError() }
			return valueGetter(this)
		}
		typedSelf().addTarget(trigger, action: trigger.action, forControlEvents: controlEvents)
		rx_disposeBag ++ AnonymousDisposable { [weak self] in // TODO should move this to Trigger deinit
			self?.typedSelf().removeTarget(trigger, action: trigger.action, forControlEvents: controlEvents)
		}
		return trigger.asTrigger()
	}
	
	public func rxs_controlEvents<T>(controlEvents: UIControlEvents, valueGetter: (Self)->T) -> Observable<T> {
		return rxs_triggerForControlEvents(controlEvents, valueGetter: valueGetter).events
	}
	
	public func rxs_controlEvents(controlEvents: UIControlEvents) -> Observable<Void> {
		return rxs_controlEvents(controlEvents, valueGetter: { _ in })
	}
	
	public func rxs_controlValueBinding<T>(valueChangeEventTypes valueChangeEventTypes: UIControlEvents, valueGetter: (Self)->T, valueSetter: (Self, T)->()) -> ValueBinding<T> {
		return ValueBinding(
			getValueTrigger: rxs_triggerForControlEvents(valueChangeEventTypes, valueGetter: valueGetter),
			setValue: { [weak self] in
				guard let this = self else { return }
				valueSetter(this, $0)
		})
	}
}

extension UIControl: UIControlType {}