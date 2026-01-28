import 'package:fpdart/fpdart.dart';
import 'errors/failures.dart';

/// Standard Result type for async operations.
/// Returns [Either] a [Failure] on error or [T] on success.
typedef FutureResult<T> = Future<Either<Failure, T>>;
