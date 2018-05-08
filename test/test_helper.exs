ExUnit.start()

Application.ensure_all_started(:plug)
Mox.defmock(UeberauthToken.TestProviderMock, for: UeberauthToken.TestProvider)
