# event_bus.gd — Global event bus for decoupled communication.
# Attach as an Autoload singleton named "EventBus".
# Usage: EventBus.something_happened.emit(args...)
extends Node

## Real-time mode signals
# warning-ignore:unused_signal
signal realtime_mode_entered()
# warning-ignore:unused_signal
signal realtime_mode_exited()

## Turn-based mode signals
# warning-ignore:unused_signal
signal turn_mode_entered()
# warning-ignore:unused_signal
signal turn_mode_exited()

## Turn system signals
# warning-ignore:unused_signal
signal turn_started(unit: Node)
# warning-ignore:unused_signal
signal turn_ended(unit: Node)
# warning-ignore:unused_signal
signal round_started(round: int)
# warning-ignore:unused_signal
signal round_ended(round: int)
# warning-ignore:unused_signal
signal turn_order_changed(order: Array)

## Unit signals
# warning-ignore:unused_signal
signal unit_damaged(unit: Node, amount: int, source: Node)
# warning-ignore:unused_signal
signal unit_evaded(target: Node, source: Node)
# warning-ignore:unused_signal
signal unit_destroyed(unit: Node)
# warning-ignore:unused_signal
signal unit_moved(unit: Node, from: Vector2, to: Vector2)
# warning-ignore:unused_signal
signal ap_changed(unit: Node)

## Combat signals
# warning-ignore:unused_signal
signal combat_started(participants: Array)
# warning-ignore:unused_signal
signal combat_ended()
# warning-ignore:unused_signal
signal combat_victory()
# warning-ignore:unused_signal
signal combat_defeat()

## Mode switch signal
# warning-ignore:unused_signal
signal game_mode_changed(mode: String)

## Movement signals
# warning-ignore:unused_signal
signal unit_skipped_turn(unit: Node)
# warning-ignore:unused_signal
signal player_ended_turn(unit: Node)

## ZOC signals
# warning-ignore:unused_signal
signal attack_of_opportunity(attacker: Node, target: Node, damage: int, hit: bool)

## Economy signals
# warning-ignore:unused_signal
signal gold_changed(unit: Node, amount: int)
