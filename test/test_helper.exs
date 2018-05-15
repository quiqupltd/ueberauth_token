ExUnit.start()

Application.ensure_all_started(:plug)
Application.ensure_all_started(:mox)
Mox.defmock(UeberauthToken.TestProviderMock, for: UeberauthToken.TestProvider)
