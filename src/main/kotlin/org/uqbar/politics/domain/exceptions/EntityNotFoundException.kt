package org.uqbar.politics.domain.exceptions

import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.ResponseStatus

@ResponseStatus(code = HttpStatus.BAD_REQUEST)
class EntityNotFoundException(message: String) : java.lang.RuntimeException(message)
